defmodule TldrWeb.RecipeLive.Components.RecipeChat do
  use TldrWeb, :live_component

  require Logger

  alias Tldr.AI.Chat

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <%!-- Messages Area --%>
      <div
        id="messages-container"
        class="flex-1 overflow-y-auto py-4 space-y-4"
        phx-hook="ScrollToBottom"
      >
        <%= if @messages == [] do %>
          <div class="flex items-center justify-center h-full text-base-content/40 text-sm">
            <p>Send a message to start the conversation</p>
          </div>
        <% else %>
          <%= for message <- @messages do %>
            <.chat_message message={message} />
          <% end %>

          <%!-- Loading indicator --%>
          <%= if @loading do %>
            <div class="flex justify-end">
              <div class="max-w-[80%] px-4 py-3 rounded-2xl rounded-br-sm bg-primary/10 text-base-content">
                <div class="flex items-center gap-2">
                  <span class="loading loading-dots loading-sm"></span>
                  <span class="text-xs text-base-content/60">Thinking...</span>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>

      <%!-- Input Area --%>
      <div class="pt-4 border-t border-base-300">
        <div class="flex gap-3 items-center">
          <input
            type="text"
            name="message"
            value={@input}
            placeholder="Type your message..."
            autocomplete="off"
            disabled={@loading}
            phx-change="update_input"
            phx-keydown="keydown"
            phx-target={@myself}
            class={[
              "flex-1 px-4 py-2.5 rounded-xl border border-base-300 bg-base-100",
              "text-base-content placeholder:text-base-content/40 text-xs",
              "focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary",
              "transition-all duration-200",
              @loading && "opacity-50 cursor-not-allowed"
            ]}
          />
          <.button
            variant="primary"
            type="button"
            disabled={@loading}
            phx-click="send"
            phx-target={@myself}
          >
            <span :if={not @loading}>Send</span>
            <span :if={@loading} class="loading loading-spinner loading-sm"></span>
          </.button>
        </div>
      </div>
    </div>
    """
  end

  # Renders a single chat message bubble.
  # User messages are aligned left, assistant messages aligned right.
  attr :message, :map, required: true

  defp chat_message(assigns) do
    ~H"""
    <div class={[
      "flex chat-markdown",
      @message.role == :user && "justify-start",
      @message.role == :assistant && "justify-end"
    ]}>
      <div class={[
        "max-w-[80%] px-4 py-3 rounded-2xl text-xs flex flex-col gap-3",
        @message.role == :user && "rounded-bl-sm bg-base-200 text-base-content",
        @message.role == :assistant && "rounded-br-sm bg-primary text-primary-content"
      ]}>
        {raw(markdown_to_html(@message.content))}
      </div>
    </div>
    """
  end

  def markdown_to_html(markdown) do
    MDEx.new(markdown: markdown) |> MDEx.to_html!()
  end

  @impl true
  def update(%{action: {:chat_response, {:ok, updated_chain}}}, socket) do
    response = Chat.get_last_response(updated_chain)
    assistant_message = %{role: :assistant, content: response}
    messages = socket.assigns.messages ++ [assistant_message]

    {:ok,
     socket
     |> assign(:messages, messages)
     |> assign(:loading, false)
     |> assign(:chain, updated_chain)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:messages, fn -> [] end)
      |> assign_new(:input, fn -> "" end)
      |> assign_new(:loading, fn -> false end)
      |> assign_new(:chain, fn ->
        Chat.new(assigns.current_scope, assigns.recipe.id)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_input", %{"message" => message}, socket) do
    {:noreply, assign(socket, :input, message)}
  end

  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    send_message(socket)
  end

  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("send", _params, socket) do
    send_message(socket)
  end

  defp send_message(socket) do
    message = socket.assigns.input

    if message != "" do
      # Add user message to the UI immediately
      user_message = %{role: :user, content: message}
      messages = socket.assigns.messages ++ [user_message]

      # Start async task to get AI response
      # Send results to this component's PID, not the parent
      chain = socket.assigns.chain

      pid = self()

      Task.Supervisor.start_child(Tldr.ChatSupervisor, fn ->
        Logger.warning("Sending message: #{message}")

        result = Chat.send_message(chain, message)

        send_update(pid, TldrWeb.RecipeLive.Components.RecipeChat,
          id: "recipe-chat",
          action: {:chat_response, result}
        )
      end)

      {:noreply,
       socket
       |> assign(:messages, messages)
       |> assign(:input, "")
       |> assign(:loading, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:chat_response, {:ok, updated_chain}}, socket) do
    # Task completed successfully
    # Extract the response and add to messages
    response = Chat.get_last_response(updated_chain)
    assistant_message = %{role: :assistant, content: response}
    messages = socket.assigns.messages ++ [assistant_message]

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:loading, false)
     |> assign(:chain, updated_chain)}
  end

  def handle_info({:chat_response, {:error, reason}}, socket) do
    # Task failed - show error
    Logger.error("Chat error: #{inspect(reason)}")

    error_message = %{role: :assistant, content: "Sorry, something went wrong. Please try again."}
    messages = socket.assigns.messages ++ [error_message]

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:loading, false)}
  end

  # Catch-all for other messages
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Mock messages for UI development - remove when done styling
  defp mock_messages do
    [
      %{role: :user, content: "Hey, can you help me with this recipe?"},
      %{
        role: :assistant,
        content: "Of course! I'd be happy to help. What would you like to know about this recipe?"
      },
      %{role: :user, content: "What's the best way to dice an onion without crying?"},
      %{
        role: :assistant,
        content: """
        Great question! Here are a few tricks to minimize tears when cutting onions:

        1. **Chill the onion** - Put it in the freezer for 10-15 minutes before cutting
        2. **Use a sharp knife** - A dull knife crushes more cells, releasing more irritants
        3. **Cut near running water** - The water helps absorb the sulfur compounds
        4. **Cut the root last** - The root has the highest concentration of enzymes

        Would you like me to walk you through the dicing technique step by step?
        """
      },
      %{role: :user, content: "Yes please!"},
      %{
        role: :assistant,
        content:
          "First, cut the onion in half from root to tip. Peel off the skin and lay each half flat on the cutting board."
      },
      %{role: :user, content: "Got it. What's next?"},
      %{
        role: :assistant,
        content:
          "Make horizontal cuts parallel to the board, but don't cut all the way through to the root. Then make vertical cuts from top to bottom, again leaving the root intact. Finally, slice across to create the dice. The root holds everything together while you work!"
      }
    ]
  end
end
