defmodule Tldr.Core.FindNested do
  @moduledoc """
  Module for finding nested (or not nested) elements in a data structure.
  """

  @doc """
  Find an element in struct with nested structs
  """
  def find(struct_enum, key, id, nested_key \\ nil)

  def find(nil, _key, _id, _nested_key), do: nil

  def find([], _key, _id, _nested_key), do: nil

  def find(struct_list, key, value, nested_key) when is_list(struct_list) do
    Enum.find_value(struct_list, fn struct ->
      cond do
        Map.get(struct, key) == value ->
          struct

        nested = Map.get(struct, nested_key) ->
          find(nested, key, value, nested_key)

        true ->
          nil
      end
    end)
  end

  def update(struct_list, key, value, nested_key, update_fn)

  def update(nil, _key, _value, _nested_key, _update_fn), do: {nil, false}
  def update([], _key, _value, _nested_key, _update_fn), do: {[], false}

  def update(struct_list, key, value, nested_key, update_fn) when is_list(struct_list) do
    do_update(struct_list, key, value, nested_key, update_fn, [])
  end

  defp do_update([], _key, _value, _nested_key, _update_fn, acc) do
    {Enum.reverse(acc), false}
  end

  defp do_update([struct | rest], key, value, nested_key, update_fn, acc) do
    cond do
      # Current struct matches - stop here!
      Map.get(struct, key) == value ->
        updated = update_fn.(struct)
        # Return: reversed acc + updated item + rest (unprocessed)
        {Enum.reverse(acc, [updated | rest]), true}

      # Try to find in nested structures
      nested = Map.get(struct, nested_key) ->
        case do_update(nested, key, value, nested_key, update_fn, []) do
          {updated_nested, true} ->
            updated_struct = Map.put(struct, nested_key, updated_nested)
            {Enum.reverse(acc, [updated_struct | rest]), true}

          {_nested, false} ->
            # Not found in nested, continue with next item
            do_update(rest, key, value, nested_key, update_fn, [struct | acc])
        end

      # No match, continue
      true ->
        do_update(rest, key, value, nested_key, update_fn, [struct | acc])
    end
  end
end
