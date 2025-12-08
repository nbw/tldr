defmodule Tldr.Kitchen.Actions.Format do
  @moduledoc """
  Formats maps data.
  """

  alias Tldr.Kitchen.Step

  @behaviour Tldr.Kitchen.Action

  use Tldr.Core.EmbeddedEctoSchema, schema: Tldr.Kitchen.Actions.JSON.HTTPGetSchema

  @primary_key false
  embedded_schema do
    field :fields, :map
  end

  def execute(%Step{actor: %__MODULE__{}} = step, input) when is_list(input) do
    Enum.reduce_while(input, {:ok, []}, fn item, {:ok, acc} ->
      case execute(step, item) do
        {:ok, response} -> {:cont, {:ok, [response | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  def execute(%Step{actor: %__MODULE__{} = action}, input) when is_map(input) do
    Enum.reduce(action.fields, {:ok, input}, fn {key, formula}, {:ok, acc} ->
      {:ok, Map.put(input, key, apply_formula(input, formula))}
    end)
  end

  def apply_formula(input, formula) do
    matches = Regex.scan(~r/\{\{([^}]+)\}\}/, formula)

    Enum.reduce(matches, formula, fn [match, key], acc ->
      value = Map.get(input, key)
      String.replace(acc, match, to_string(value))
    end)
  end
end
