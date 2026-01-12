defmodule Tldr.Feed do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Chef

  def cook_recipe(%Recipe{} = recipe) do
    with {:ok, result} <- Chef.cook(recipe) do
      cond do
        is_list(result) ->
          Enum.map(result, &Tldr.Feed.FeedProtocol.apply/1)

        result ->
          Tldr.Feed.FeedProtocol.apply(result)
      end

      # |> Enum.map(fn item ->
      #   Map.put(item, "source", recipe.name)
      # end)
    end
  end
end
