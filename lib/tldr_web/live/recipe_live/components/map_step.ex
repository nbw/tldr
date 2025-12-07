defmodule TldrWeb.RecipeLive.Components.MapStep do
  use TldrWeb, :html

  import TldrWeb.RecipeLive.Components.Helpers

  alias Tldr.Kitchen.Step

  def step_params_inputs(%{action: "map"} = assigns) do
    ~H"""
    <div>
      <p class="text-sm text-gray-500 italic">
        Map iterates over each item and applies the nested steps below.
      </p>
      <div class="ml-4 mt-4 border-l-2 border-emerald-300 pl-4">
        <h4 class="font-medium text-sm text-gray-600 mb-2">Nested Steps</h4>

        <%!-- <.inputs_for :let={nested_step_form} field={@step_form[:steps]}>
          <.step_fields
            step_form={nested_step_form}
            parent_name={"#{@parent_name}[steps][#{@step_form.index}]"}
            depth={@depth + 1}
          />
        </.inputs_for> --%>

        <button
          type="button"
          phx-click="add_nested_step"
          phx-value-id={step_id(@step_form)}
          phx-value-index={step_index(@step_form)}
          class="block w-full mt-2 border border-emerald-400 bg-emerald-100 rounded p-2 text-emerald-700 text-center text-sm hover:bg-emerald-200"
        >
          <.icon name="hero-plus-circle" class="w-4 h-4" /> Add nested step
        </button>
      </div>
    </div>
    """
  end

  # defp step_fields(assigns) do
  #   action = Phoenix.HTML.Form.input_value(assigns.step_form, :action)
  #   assigns = assign(assigns, :current_action, action)

  #   ~H"""
  #   <div class="border border-gray-300 rounded p-4 relative space-y-3 my-4">
  #     <input type="hidden" name={"#{@parent_name}[steps_sort][]"} value={@step_form.index} />

  #     <.input field={@step_form[:title]} type="text" label="Step Name" />

  #     <.input
  #       field={@step_form[:action]}
  #       type="select"
  #       label="Action"
  #       prompt="Select an action..."
  #       options={action_options()}
  #     />

  #     <.step_params_inputs step_form={@step_form} action={@current_action} />

  #     <%!-- Nested steps for "map" action --%>
  #     <div class="ml-4 mt-4 border-l-2 border-emerald-300 pl-4">
  #       <h4 class="font-medium text-sm text-gray-600 mb-2">Nested Steps</h4>

  #       <.inputs_for :let={nested_step_form} field={@step_form[:steps]}>
  #         <.step_fields
  #           step_form={nested_step_form}
  #           parent_name={"#{@parent_name}[steps][#{@step_form.index}]"}
  #           depth={@depth + 1}
  #         />
  #       </.inputs_for>

  #       <button
  #         type="button"
  #         phx-click="step-map:add_nested_step"
  #         phx-value-id={step_id(@step_form)}
  #         phx-value-index={step_index(@step_form)}
  #         class="block w-full mt-2 border border-emerald-400 bg-emerald-100 rounded p-2 text-emerald-700 text-center text-sm hover:bg-emerald-200"
  #       >
  #         <.icon name="hero-plus-circle" class="w-4 h-4" /> Add nested step
  #       </button>
  #     </div>

  #     <button
  #       type="button"
  #       phx-click="delete_step"
  #       phx-value-index={step_index(@step_form)}
  #       class="absolute top-2 right-2 text-red-600 hover:text-red-800"
  #     >
  #       <.icon name="hero-trash" class="w-5 h-5" />
  #     </button>
  #   </div>
  #   """
  # end

  def handle_event("add_nested_step", %{"id" => id}, socket) do
    # Add step nested under another step
    changeset = socket.assigns.form.source

    steps = Ecto.Changeset.get_field(changeset, :steps, [])
    index = Enum.find_index(steps, &(&1.id == id))
    step = Enum.at(steps, index)

    new_nested_step = %Step{id: Ecto.UUID.generate()}
    updated_step = %{step | steps: (step.steps || []) ++ [new_nested_step]}
    updated_steps = List.replace_at(steps, index, updated_step)

    new_changeset =
      changeset
      |> Ecto.Changeset.put_embed(:steps, updated_steps)
      |> Map.put(:changes, Map.put(changeset.changes, :steps, updated_steps))

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end
end
