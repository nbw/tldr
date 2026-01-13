defmodule TldrWeb.RecipeLive.Chat do
  use TldrWeb, :live_view

  alias Tldr.Kitchen
  alias TldrWeb.RecipeLive.Components.RecipeChat

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

        <%!-- Chat Component --%>
        <.live_component
          module={RecipeChat}
          id="recipe-chat"
          current_scope={@current_scope}
          recipe={@recipe}
        />
      </div>
    </Layouts.app>
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

    {:ok,
     socket
     |> assign(:recipe, recipe)}
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
