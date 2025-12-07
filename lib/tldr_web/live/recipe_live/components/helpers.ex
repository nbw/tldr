defmodule TldrWeb.RecipeLive.Components.Helpers do
  # Helper to get param value from form
  def get_param_value(form, key) do
    params = Phoenix.HTML.Form.input_value(form, :params) || %{}

    case params do
      %{^key => value} ->
        value

      %{} ->
        # Try string key
        string_key = to_string(key)
        Map.get(params, string_key)

      _ ->
        nil
    end
  end

  # Helper to get extract fields from a step
  def get_extract_fields(step_form) do
    params = Phoenix.HTML.Form.input_value(step_form, :params) || %{}
    fields = Map.get(params, :fields) || Map.get(params, "fields") || %{}

    # Convert to list of tuples for iteration
    case fields do
      map when is_map(map) -> Map.to_list(map)
      _ -> []
    end
  end

  def step_id(form) do
    case form.source do
      %Ecto.Changeset{data: %{id: id}} when is_binary(id) and byte_size(id) > 0 -> "#{id}"
      %Ecto.Changeset{changes: %{id: id}} when is_binary(id) and byte_size(id) > 0 -> "#{id}"
      _ -> nil
    end
  end

  # Build a path string for identifying nested steps
  def step_index(form) do
    # This creates a path like "0" or "0.steps.1" for nested steps
    case form.source do
      %Ecto.Changeset{} -> "#{form.index}"
      _ -> ""
    end
  end
end
