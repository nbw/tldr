defmodule TldrWeb.RecipeLive.Components.FormatStep do
  use TldrWeb, :html

  alias Tldr.Core

  import TldrWeb.RecipeLive.Components.Helpers

  def step_params_inputs(%{action: "format"} = assigns) do
    ~H"""
    <div class="bg-gray-50 p-3 rounded">
      <p class="text-sm text-gray-600 mb-3">
        Format the input map using functions for each field. If a function isn't present the original value is used.
      </p>
      <div class="space-y-2 mb-3">
        <% fields = get_extract_fields(@step_form) %>
        <%= if fields == [] do %>
          <p class="text-sm text-gray-500 italic">No fields configured yet.</p>
        <% else %>
          <div :for={{idx, %{"key" => key, "value" => value}} <- fields}>
            <div class="flex gap-2 items-center bg-white p-2 rounded border border-gray-200">
              <input
                type="text"
                name={"#{@step_form.name}[params][fields][#{idx}][key]"}
                value={key}
                placeholder="Field name"
                class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
              />
              <span class="text-gray-400">→</span>
              <input
                type="text"
                name={"#{@step_form.name}[params][fields][#{idx}][value]"}
                value={value}
                placeholder="Formatted string (e.g., http://example.com/{{val}})"
                class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
              />
              <button
                type="button"
                phx-click="step-format:remove_format_field"
                phx-value-id={step_id(@step_form)}
                phx-value-idx={idx}
                class="text-red-600 hover:text-red-800 text-sm"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </button>
            </div>
          </div>
        <% end %>
      </div>

      <button
        type="button"
        phx-click="step-format:add_format_field"
        phx-value-id={step_id(@step_form)}
        phx-value-index={step_index(@step_form)}
        class="block w-full border border-emerald-400 bg-emerald-100 rounded p-2 text-emerald-700 text-center text-sm hover:bg-emerald-200"
      >
        <.icon name="hero-plus-circle" class="w-4 h-4" /> Add field
      </button>
    </div>
    """
  end

  def handle_event("add_format_field", %{"id" => id}, socket) do
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

  def handle_event("remove_format_field", %{"id" => id, "idx" => idx}, socket) do
    changeset = socket.assigns.form.source

    steps =
      Ecto.Changeset.get_field(changeset, :steps, [])
      |> Core.StructToMap.transform()

    step_index = Enum.find_index(steps, &(&1.id == id))

    step = Enum.at(steps, step_index)

    current_fields = ((step.params || %{})["fields"] || %{})

    updated_fields = Map.delete(current_fields, idx)

    updated_params = Map.put(step.params || %{}, "fields", updated_fields)

    updated_step = %{step | params: updated_params}

    updated_steps = List.replace_at(steps, step_index, updated_step)

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, updated_steps)

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end
end
