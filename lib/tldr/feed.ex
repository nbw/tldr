defmodule Tldr.Feed do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Chef

  require Logger

  def cook_recipe(%Recipe{} = recipe) do
    with {:ok, results} <- Chef.cook(recipe) do
      dbg(results)

      Enum.reduce_while(results, {:ok, []}, fn result, {:ok, acc} ->
        case Tldr.Feed.FeedProtocol.apply(result) do
          {:ok, item} ->
            {:cont, {:ok, [item | acc]}}

          {:error, reason} ->
            Logger.error("Error applying feed protocol: #{inspect(reason)}")
            {:halt, {:error, reason}}
        end
      end)
    end
  end
end
