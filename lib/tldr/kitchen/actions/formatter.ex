defmodule Tldr.Kitchen.Actions.Formatter do
  @moduledoc """
  Extracts and formats data from maps using JSONPath and direct access.

  Supports three modes:
  1. JSONPath extraction: "$.topic_list.topics" - extracts value using JSONPath (starts with $)
  2. Constant string: "https://example.com/latest" - returns the string as-is
  3. String interpolation with two sub-modes:
     - Direct access: "https://example.com/{{slug}}" - accesses input["slug"] directly
     - JSONPath: "https://example.com/{{$.slug}}" - evaluates $.slug using Warpath

  Note: The {{}} delimiters must be properly matched or an error will be returned.
  """

  alias Tldr.Kitchen.Step

  @behaviour Tldr.Kitchen.Action

  use Tldr.Core.EmbeddedEctoSchema, schema: Tldr.Kitchen.Actions.JSON.HTTPGetSchema

  @primary_key false
  embedded_schema do
    field :fields, :map
  end

  @spec execute(Tldr.Kitchen.Step.t(), maybe_improper_list() | map(), any()) :: any()
  def execute(step, input, opts \\ [])

  def execute(%Step{actor: %__MODULE__{}} = step, input, opts) when is_list(input) do
    Enum.reduce_while(input, {:ok, []}, fn item, {:ok, acc} ->
      case execute(step, item, opts) do
        {:ok, response} -> {:cont, {:ok, [response | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, results} -> {:ok, Enum.reverse(results)}
      error -> error
    end
  end

  def execute(%Step{actor: %__MODULE__{}} = step, input, opts) when is_map(input) do
    case maybe_apply_index(step, input) do
      {:index, step, input} ->
        execute(step, input, opts)

      {:skip, step, input} ->
        process_fields(step.actor.fields, input)

      error ->
        error
    end
  end

  defp maybe_apply_index(
         %Step{actor: %__MODULE__{fields: %{"_index" => _} = fields}} = step,
         input
       ) do
    {index_field, other_fields} = Map.split(fields, ["_index"])

    with {:ok, new_input} <- process_fields(index_field, input) do
      {:index, %{step | actor: %__MODULE__{fields: other_fields}}, new_input}
    end
  end

  defp maybe_apply_index(step, input) do
    {:skip, step, input}
  end

  defp process_fields(fields, input) when map_size(fields) == 0 do
    {:ok, input}
  end

  defp process_fields(fields, input) do
    Enum.reduce_while(
      fields,
      {:ok, %{}},
      fn {key, pattern}, {:ok, acc} ->
        case process_pattern(pattern, input) do
          {:ok, value} -> {:cont, {:ok, Map.put(acc, key, value)}}
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

  defp process_pattern(pattern, input) when is_binary(pattern) do
    cond do
      # Check if pattern contains interpolation markers {{...}}
      is_interpolation?(pattern) ->
        case valid_interpolation?(pattern) do
          {:error, reason} ->
            {:error, reason}

          {:ok, matches} ->
            interpolate(pattern, matches, input)
        end

      # JSONPath extraction (starts with $)
      is_jsonpath?(pattern) ->
        query_jsonpath(input, pattern)

      # Constant string
      true ->
        {:ok, pattern}
    end
  end

  defp interpolate(template, matches, input) do
    Enum.reduce_while(matches, {:ok, template}, fn [match, key], {:ok, acc} ->
      trimmed_key = String.trim(key)

      result =
        if is_jsonpath?(trimmed_key) do
          # JSONPath evaluation
          query_jsonpath(input, trimmed_key)
        else
          # Direct map access
          {:ok, Map.get(input, trimmed_key)}
        end

      case result do
        {:ok, value} ->
          {:cont, {:ok, String.replace(acc, match, to_string(value))}}

        {:error, reason} ->
          {:halt, {:error, "Failed to evaluate #{trimmed_key}: #{inspect(reason)}"}}
      end
    end)
  end

  defp query_jsonpath(input, pattern) do
    Warpath.query(input, pattern)
  end

  def is_interpolation?(pattern) do
    String.contains?(pattern, "{{")
  end

  def is_jsonpath?(pattern) do
    String.starts_with?(pattern, "$")
  end

  def valid_interpolation?(string) when is_binary(string) do
    # number of expected interpolations
    open_count = length(Regex.scan(~r/\{\{/, string))
    close_count = length(Regex.scan(~r/\}\}/, string))

    # Find all matches for {{...}}
    full_matches = Regex.scan(~r/\{\{([^}]*)\}\}/, string)

    full_matches_count = length(full_matches)

    cond do
      full_matches_count != open_count || open_count != close_count ->
        {:error, "Unmatched {{ or }} in value: #{string}"}

      Enum.any?(full_matches, fn [_, match] -> String.contains?(match, ["{{", "}}"]) end) ->
        {:error, "Invalid format or contains nested interpolation"}

      true ->
        {:ok, full_matches}
    end
  end

  def summary(payload) when is_list(payload) do
    if length(payload) > 0 do
      """
      Formatter: returned #{length(payload)} items. First item:
      ```json
      #{List.first(payload) |> JSON.encode!()}
      ```
      """
    else
      """
      Formatter: returned 0 items.
      """
    end
  end

  def summary(payload) when is_map(payload) do
    """
    Formatter: returned an object, not a list of items. Object keys: #{Map.keys(payload) |> Enum.join(", ")}
    """
  end

  def summary(_payload) do
    """
    Formatter: error - returned neither a list or map.
    """
  end
end
