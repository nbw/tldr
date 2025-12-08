defmodule TldrWeb.RecipeLive.FormHelpers do
  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Step

  # converts params into shape required for a Phoenix Form
  def decode_params_for_form(%Recipe{steps: steps} = recipe) do
     transformed_steps = Enum.map(steps, &decode_transform_step_params/1)

     %{recipe | steps: transformed_steps}
  end

  def decode_params_for_form(params), do: params

  defp decode_transform_step_params(
    %Step{action: action, params: %{"fields" => fields}} = step
  ) when is_map(fields) and action in ["extract", "format"] do
    # Convert from %{"kagi" => "$.title", ...}
    # to %{"0" => %{"key" => "kagi", "value" => "$.title"}, "1" => {...}}
    transformed_fields =
      fields
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{key, value}, idx}, acc ->
        Map.put(acc, Integer.to_string(idx), %{"key" => key, "value" => value})
      end)

    %{step | params: Map.put(step.params || %{}, "fields", transformed_fields)}
  end

  defp decode_transform_step_params(params), do: params

  # converts form params into shape required for saving a Step
  def encode_params_for_save(%{"steps" => steps} = params) when is_map(steps) do
    transformed_steps =
      steps
      |> Enum.map(fn {idx, step} ->
        {idx, encode_transform_step_params(step)}
      end)
      |> Map.new()

    %{params | "steps" => transformed_steps}
  end

  def encode_params_for_save(params), do: params

  def encode_transform_step_params(
         %{"action" => action, "params" => %{"fields" => fields}} = step
       ) when is_map(fields) and action in ["extract", "format"] do
    # Convert from %{"0" => %{"key" => "kagi", "value" => "$.title"}, "1" => {...}}
    # to %{"kagi" => "$.title", ...}
    transformed_fields =
      fields
      |> Enum.reduce(%{}, fn {_idx, %{"key" => key, "value" => value}}, acc ->
        Map.put(acc, key, value)
      end)

    put_in(step, ["params", "fields"], transformed_fields)
  end

  def encode_transform_step_params(
         %{action: action, params: %{"fields" => fields}} = step
       ) when is_map(fields) and action in ["extract", "format"] do
    # Convert from %{"0" => %{"key" => "kagi", "value" => "$.title"}, "1" => {...}}
    # to %{"kagi" => "$.title", ...}
    transformed_fields =
      fields
      |> Enum.reduce(%{}, fn {_idx, %{"key" => key, "value" => value}}, acc ->
        Map.put(acc, key, value)
      end)

    put_in(step, [:params, "fields"], transformed_fields)
  end

  def encode_transform_step_params(step), do: step

  def step_status(step_statuses, step_form) do
    id = Phoenix.HTML.Form.input_value(step_form, :id)

    Map.get(step_statuses, id, %{})
    |> Map.get(:status)
  end

  def step_preview(step_statuses, step_form) do
    id = Phoenix.HTML.Form.input_value(step_form, :id)

    Map.get(step_statuses, id, %{})
    |> Map.get(:preview)
  end
end
