defmodule Tldr.Core.StructToMap do
  @moduledoc """
  Converts a struct to a map, but specifically recursively
  over nested structs and lists of structs.
  """

  @doc false
  def transform(data) when is_struct(data) do
    data
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, transform(value)} end)
    |> Map.new()
  end

  def transform(data) when is_list(data), do: Enum.map(data, &transform/1)

  def transform(data), do: data
end
