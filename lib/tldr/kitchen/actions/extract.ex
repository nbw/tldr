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

  def execute(%Step{actor: %__MODULE__{}} = step, input) when is_list(input) do
    Enum.reduce_while(input, {:ok, []}, fn item, {:ok, acc} ->
      case execute(step, item) do
        {:ok, response} -> {:cont, {:ok, [response | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  def execute(%Step{actor: %__MODULE__{}} = step, input) when is_map(input) do
    with {:ok, step, input} <- maybe_apply_index(step, input) do
      extract(step.actor.fields, input)
    end
  end

  defp maybe_apply_index(
         %Step{actor: %__MODULE__{fields: %{"_index" => _} = fields}} = step,
         input
       ) do
    {index_field, other_fields} = Map.split(fields, ["_index"])

    with {:ok, new_input} <- extract(index_field, input) do
      {:ok, %{step | actor: %__MODULE__{fields: other_fields}}, new_input}
    end
  end

  defp maybe_apply_index(step, input) do
    {:ok, step, input}
  end

  defp extract(fields, input) when map_size(fields) == 0 do
    {:ok, input}
  end

  defp extract(fields, input) do
    Enum.reduce_while(
      fields,
      {:ok, %{}},
      fn {k, v}, {:ok, acc} ->
        case Warpath.query(input, v) do
          {:ok, value} -> {:cont, {:ok, Map.put(acc, k, value)}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end
    )
    |> case do
      {:ok, %{"_index" => result}} -> {:ok, result}
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end
end
