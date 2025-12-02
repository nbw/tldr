defmodule Tldr.Kitchen.Actions.Map do
  @moduledoc "Map over and apply steps"

  @behaviour Tldr.Kitchen.Action

  alias Tldr.Kitchen.Step

  use Tldr.Core.EmbeddedEctoSchema, schema: Tldr.Kitchen.Actions.JSON.HTTPGetSchema

  embedded_schema do
  end

  def execute(%Step{action: %__MODULE__{}, steps: steps}, base_input) when is_list(base_input) do
    # TODO ERROR HANDLING
    result =
      Enum.map(base_input, fn input ->
        case Tldr.Kitchen.Chef.cook(input, steps) do
          {:ok, output} -> output
          {:error, reason} -> {:error, reason}
        end
      end)

    {:ok, result}
  end

  def execute(_action, _input) do
    {:error, :invalid_input}
  end
end
