defprotocol Tldr.AI.Minifier do
  @moduledoc """
  Reduces the size of data payloads sent to a language model (LLM) by providing minimal samples
  rather than complete structures. This helps lower token usage, bandwidth, and cost for LLM calls,
  making results more efficient without sacrificing information about data shape.

  The minifier can be used on any data intended for the LLM, such as API responses, Ecto structs,
  or simple maps, not just JSON.
  """
  @fallback_to_any true
  def minify(data)
end

defimpl Tldr.AI.Minifier, for: Map do
  def minify(data) do
    data
    |> Enum.map(fn {key, value} -> {key, Tldr.AI.Minifier.minify(value)} end)
    |> Map.new()
  end
end

defimpl Tldr.AI.Minifier, for: List do
  @doc """
  Recursively traverses a map, list, or other nested data structure and collapses data to the
  minimum representative sample needed for an LLM to infer its structure.

  - Lists/arrays are reduced to a single element (the first, if present)
  - Strings longer than 100 characters are truncated to 100 characters and suffixed with "..."
  - All other values are left intact

  Useful for shrinking large payloads and avoiding unnecessary verbosity when communicating with LLMs.
  """
  def minify(data) do
    case data do
      [] -> []
      [first | _rest] -> [Tldr.AI.Minifier.minify(first)]
    end
  end
end

defimpl Tldr.AI.Minifier, for: BitString do
  def minify(data) do
    if String.length(data) > 100 do
      String.slice(data, 0, 100) <> "..."
    else
      data
    end
  end
end

defimpl Tldr.AI.Minifier, for: Any do
  require Logger

  def minify(data) do
    data
  end
end
