defmodule TldrWeb.RecipeLive.Components.FormatterStep do
  use TldrWeb, :html

  use TldrWeb.RecipeLive.Components.StepComponent

  alias Tldr.Core

  import TldrWeb.RecipeLive.Components.Helpers

  def step_params_inputs(%{action: "formatter"} = assigns) do
    ~H"""
    <div class="p-3 rounded">
      <p class="text-sm text-base-content/70 mb-3">
        Extract fields from the input data using JSON paths.
      </p>
      <div class="space-y-2 mb-3">
        <% fields = get_extract_fields(@step_form) %>
        <%= if fields == [] do %>
          <p class="text-sm text-base-content/70 italic">No fields configured yet.</p>
        <% else %>
          <div :for={{idx, %{"key" => key, "value" => value}} <- fields}>
            <div class="flex gap-2 items-center p-2 rounded border border-gray-200/50">
              <input
                type="text"
                name={"#{@step_form.name}[params][fields][#{idx}][key]"}
                value={key}
                placeholder="Field name"
                class="flex-1 px-2 py-1 border border-gray-300/50 rounded text-sm"
              />
              <span class="text-base-content/50">→</span>
              <input
                type="text"
                name={"#{@step_form.name}[params][fields][#{idx}][value]"}
                value={value}
                placeholder="JSON path (e.g., $.title)"
                class="flex-1 px-2 py-1 border border-gray-300/50 rounded text-sm"
              />
              <button
                :if={!@locked}
                type="button"
                phx-click="step-extract:remove_extract_field"
                phx-value-id={step_id(@step_form)}
                phx-value-idx={idx}
                class="text-rose-400 hover:text-rose-500 text-sm"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </button>
            </div>
          </div>
        <% end %>
      </div>

      <button
        :if={!@locked}
        type="button"
        phx-click="step-formatter:add_formatter_field"
        phx-value-id={step_id(@step_form)}
        phx-value-index={step_index(@step_form)}
        class="mx-auto block w-full max-w-[10rem] border border-gray-400/70 bg-gray-300/50 rounded p-2 text-gray-700 text-center text-sm hover:bg-gray-300/60"
      >
        <.icon name="hero-plus-circle" class="w-6 h-6" /> Add Field
      </button>
    </div>
    """
  end

  def handle_event("add_formatter_field", %{"id" => id}, socket) do
    changeset = socket.assigns.form.source

    steps =
      Ecto.Changeset.get_field(changeset, :steps, [])
      |> Core.StructToMap.transform()

    step_index = Enum.find_index(steps, &(&1.id == id))

    step = Enum.at(steps, step_index)

    current_fields = (step.params || %{})["fields"] || %{}

    # Add a new empty field entry - use indexed structure
    new_idx = map_size(current_fields)

    updated_fields = Map.put(current_fields, "#{new_idx}", %{"key" => "", "value" => ""})
    updated_params = Map.put(step.params || %{}, "fields", updated_fields)
    updated_step = %{step | params: updated_params}

    updated_steps = List.replace_at(steps, step_index, updated_step)

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, updated_steps)

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  def handle_event("remove_extract_field", %{"id" => id, "idx" => idx}, socket) do
    changeset = socket.assigns.form.source

    steps =
      Ecto.Changeset.get_field(changeset, :steps, [])
      |> Core.StructToMap.transform()

    step_index = Enum.find_index(steps, &(&1.id == id))

    step = Enum.at(steps, step_index)

    current_fields = (step.params || %{})["fields"] || %{}

    updated_fields = Map.delete(current_fields, idx)

    updated_params = Map.put(step.params || %{}, "fields", updated_fields)

    updated_step = %{step | params: updated_params}

    updated_steps = List.replace_at(steps, step_index, updated_step)

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, updated_steps)

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end
end
