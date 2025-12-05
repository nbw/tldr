defmodule Tldr.Kitchen.Actions.Extract do
  @moduledoc """
  Extracts data from a list of maps.
  """

  alias Tldr.Kitchen.Step

  @behaviour Tldr.Kitchen.Action

  use Tldr.Core.EmbeddedEctoSchema, schema: Tldr.Kitchen.Actions.JSON.HTTPGetSchema

  @primary_key false
  embedded_schema do
    field :fields, :map
  end

  def execute(%Step{actor: %__MODULE__{} = action}, input) do
    Enum.reduce_while(action.fields, {:ok, %{}}, fn {k, v}, {:ok, acc} ->
      case Warpath.query(input, v) do
        {:ok, value} -> {:cont, {:ok, Map.put(acc, k, value)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end
