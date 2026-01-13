defmodule TldrWeb.RecipeLive.Components.Step do
  use TldrWeb, :html

  import TldrWeb.RecipeLive.Components.Helpers

  attr :step_form, :any, required: true
  attr :locked, :boolean, default: false
  attr :parent_name, :string, required: true
  attr :step_status, :atom, required: true
  attr :step_preview, :any, required: true

  def step(assigns) do
    id = Phoenix.HTML.Form.input_value(assigns.step_form, :id)
    action = Phoenix.HTML.Form.input_value(assigns.step_form, :action)
    locked = Phoenix.HTML.Form.input_value(assigns.step_form, :locked)

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:current_action, action)
      |> assign(:locked, locked)

    ~H"""
    <div
      class="border border-gray-400/50 bg-base-100/90 rounded-sm flex min-w-xl"
      id={"step-#{@id}"}
    >
      <div class="grow p-4 relative">
        <input type="hidden" name={"#{@parent_name}[steps_sort][]"} value={@step_form.index} />
        <.input field={@step_form[:title]} type="text" label="Step Name" />
        <.input field={@step_form[:index]} type="hidden" hidden />
        <%= if @locked do %>
          <.input field={@step_form[:action]} type="hidden" label="" value={@current_action} hidden />
        <% else %>
          <.input
            field={@step_form[:action]}
            type="select"
            label="Action"
            prompt="Select an action..."
            options={action_options()}
          />
        <% end %>
        <.step_params_inputs step_form={@step_form} action={@current_action} locked={@locked} />
        <div>
          <div :if={@step_preview && @step_status == :success}>
            <div id={"preview-#{@id}-toggle"} class="text-center my-2">
              <div phx-click={
                JS.toggle(to: "#preview-#{@id}")
                |> JS.dispatch("highlight-code", to: "#preview-#{@id}")
                |> JS.hide(to: "#preview-#{@id}-toggle")
              }>
                <.icon name="hero-chevron-down" class="w-5 h-5" />
              </div>
            </div>
            <div
              id={"preview-#{@id}"}
              phx-hook="HighlightCode"
              class="max-h-[29rem] max-w-full overflow-scroll hidden"
            >
              <pre class="whitespace-pre-wrap break-words text-xs"><code class="language-elixir">
    {inspect(@step_preview, pretty: true)}
                </code></pre>
              <div class="text-center my-2">
                <div phx-click={
                  JS.toggle(to: "#preview-#{@id}")
                  |> JS.show(to: "#preview-#{@id}-toggle")
                }>
                  <.icon name="hero-chevron-up" class="w-5 h-5" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="flex flex-col justify-center items-center">
        <div class="border border-gray-300/50 rounded-lg flex flex-col justify-center items-center gap-8 p-2 m-4  h-full max-h-[15rem]">
          <div>
            <%= case @step_status do %>
              <% :loading -> %>
                <div class="flex justify-center">
                  <svg
                    class="size-5 animate-spin text-normal"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    >
                    </path>
                  </svg>
                </div>
              <% :success -> %>
                <div phx-click="preview" phx-value-id={@step_form.data.id}>
                  <.icon
                    name="hero-check-circle text-sm text-emerald-500 opacity-70 hover:opacity-50"
                    class="w-6 h-6"
                  />
                </div>
              <% :error -> %>
                <div>
                  <.icon
                    name="hero-exclamation-circle text-rose-500 text-sm opacity-70"
                    class="w-6 h-6"
                  />
                </div>
              <% _ -> %>
                <div phx-click="preview" phx-value-id={@step_form.data.id}>
                  <.icon name="hero-play-circle opacity-70" class="w-6 h-6 hover:opacity-50" />
                </div>
            <% end %>
          </div>
          <div :if={!@locked}>
            <.icon name="hero-arrow-up-circle opacity-70" class="w-6 h-6 hover:opacity-50" />
          </div>
          <div :if={!@locked}>
            <.icon name="hero-arrow-down-circle opacity-70" class="w-6 h-6 hover:opacity-50" />
          </div>
          <div :if={!@locked}>
            <button
              type="button"
              phx-click="delete_step"
              phx-value-index={step_index(@step_form)}
              class="text-rose-400 hover:text-rose-500"
            >
              <.icon name="hero-trash" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp action_options do
    [
      {"API", "api"},
      {"Limit", "limit"},
      {"Format", "formatter"}
    ]
  end

  # Dynamic params inputs based on action type
  defp step_params_inputs(%{action: nil} = assigns), do: ~H""
  defp step_params_inputs(%{action: ""} = assigns), do: ~H""

  defp step_params_inputs(%{action: action} = assigns) do
    step_component = get_step_component(action)
    step_component.step_params_inputs(assigns)
  end
end
