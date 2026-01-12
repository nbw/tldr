defmodule TldrWeb.RecipeLive.Chat do
  use TldrWeb, :live_view

  require Logger

  alias Tldr.Kitchen
  alias Tldr.AI.Chat

  import TldrWeb.RecipeLive.FormHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} class="">
      <div class="flex flex-col h-[calc(100vh-8rem)] mx-auto max-w-4xl border border-base-300 rounded-lg p-4">
        <%!-- Header --%>
        <div class="pb-4 border-b border-base-300">
          <h1 class="text-xl font-semibold text-base-content">Recipe Chat</h1>
          <p class="text-sm text-base-content/60">{@recipe.name}</p>
        </div>

        <%!-- Messages Area --%>
        <div
          id="messages-container"
          class="flex-1 overflow-y-auto py-4 space-y-4"
          phx-hook="ScrollToBottom"
        >
          <%= if @messages == [] do %>
            <div class="flex items-center justify-center h-full text-base-content/40">
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
                    <span class="text-sm text-base-content/60">Thinking...</span>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>

        <%!-- Input Area --%>
        <div class="pt-4 border-t border-base-300">
          <form id="chat-form" phx-submit="send" class="flex gap-3">
            <input
              type="text"
              name="message"
              value={@input}
              placeholder="Type your message..."
              autocomplete="off"
              disabled={@loading}
              class={[
                "flex-1 px-4 py-3 rounded-xl border border-base-300 bg-base-100",
                "text-base-content placeholder:text-base-content/40",
                "focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary",
                "transition-all duration-200",
                @loading && "opacity-50 cursor-not-allowed"
              ]}
            />
            <button
              type="submit"
              disabled={@loading}
              class={[
                "px-6 py-3 rounded-xl font-medium transition-all duration-200",
                "bg-primary text-primary-content",
                "hover:bg-primary/90 active:scale-95",
                "disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100"
              ]}
            >
              <span :if={not @loading}>Send</span>
              <span :if={@loading} class="loading loading-spinner loading-sm"></span>
            </button>
          </form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Renders a single chat message bubble.
  # User messages are aligned left, assistant messages aligned right.
  attr :message, :map, required: true

  defp chat_message(assigns) do
    ~H"""
    <div class={[
      "flex",
      @message.role == :user && "justify-start",
      @message.role == :assistant && "justify-end"
    ]}>
      <div class={[
        "max-w-[80%] px-4 py-3 rounded-2xl",
        @message.role == :user && "rounded-bl-sm bg-base-200 text-base-content",
        @message.role == :assistant && "rounded-br-sm bg-primary text-primary-content"
      ]}>
        <p class="whitespace-pre-wrap break-words">{@message.content}</p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    current_scope = socket.assigns.current_scope

    recipe =
      current_scope
      |> Kitchen.get_recipe!(id)
      |> decode_params_for_form()

    if connected?(socket) do
      TldrWeb.PubSub.subscribe("recipe:#{id}")
    end

    # Initialize a new chat chain
    chain = Chat.new(current_scope, id)

    {:ok,
     socket
     |> assign(:recipe, recipe)
     |> assign(:messages, [])
     |> assign(:input, "")
     |> assign(:loading, false)
     |> assign(:chain, chain)}
  end

  @impl true
  def handle_event("send", %{"message" => message}, socket) when message != "" do
    # Add user message to the UI immediately
    user_message = %{role: :user, content: message}
    messages = socket.assigns.messages ++ [user_message]

    # Start async task to get AI response
    # This prevents blocking the LiveView process
    chain = socket.assigns.chain
    task = Task.async(fn -> Chat.send_message(chain, message) end)

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:input, "")
     |> assign(:loading, true)
     |> assign(:pending_task, task)}
  end

  def handle_event("send", _params, socket) do
    # Ignore empty messages
    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, {:ok, updated_chain}}, socket) when is_reference(ref) do
    # Task completed successfully - clean up the task reference
    Process.demonitor(ref, [:flush])

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

  def handle_info({ref, {:error, reason}}, socket) when is_reference(ref) do
    # Task failed - clean up and show error
    Process.demonitor(ref, [:flush])
    Logger.error("Chat error: #{inspect(reason)}")

    error_message = %{role: :assistant, content: "Sorry, something went wrong. Please try again."}
    messages = socket.assigns.messages ++ [error_message]

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:loading, false)}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    # Task process died unexpectedly
    {:noreply, assign(socket, :loading, false)}
  end

  # Catch-all for other messages (like PubSub)
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end

# =============================================================================
# STREAMING IMPLEMENTATION NOTES
# =============================================================================
#
# To convert this to streaming responses, you would make these changes:
#
# 1. In Tldr.AI.Chat, add a streaming function:
#
#    def send_message_streaming(chain, content, live_view_pid) do
#      callback = fn
#        %LangChain.MessageDelta{} = delta ->
#          send(live_view_pid, {:stream_delta, delta})
#        %LangChain.Message{} = _message ->
#          send(live_view_pid, :stream_complete)
#      end
#
#      chain
#      |> LLMChain.add_message(Message.new_user!(content))
#      |> LLMChain.run(stream: true, callback_fn: callback)
#    end
#
# 2. In the LiveView handle_event("send", ...), call the streaming version:
#
#    task = Task.async(fn ->
#      Chat.send_message_streaming(chain, message, self())
#    end)
#
# 3. Add a new handle_info for streaming deltas:
#
#    def handle_info({:stream_delta, delta}, socket) do
#      # delta.content contains the partial text
#      # Append to a "streaming_content" assign
#      current = socket.assigns[:streaming_content] || ""
#      {:noreply, assign(socket, :streaming_content, current <> (delta.content || ""))}
#    end
#
#    def handle_info(:stream_complete, socket) do
#      # Move streaming_content to a proper message
#      content = socket.assigns.streaming_content
#      message = %{role: :assistant, content: content}
#      messages = socket.assigns.messages ++ [message]
#
#      {:noreply,
#       socket
#       |> assign(:messages, messages)
#       |> assign(:streaming_content, nil)
#       |> assign(:loading, false)}
#    end
#
# 4. In the template, show the streaming content while it's being received:
#
#    <%= if @streaming_content do %>
#      <div class="flex justify-end">
#        <div class="...">
#          <p>{@streaming_content}</p>
#          <span class="loading loading-dots loading-xs"></span>
#        </div>
#      </div>
#    <% end %>
#
