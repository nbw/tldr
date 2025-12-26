defmodule Tldr.Feed do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Chef
  alias Tldr.Feed.Schema.IndexItem

  def cook_recipe(%Recipe{} = recipe) do
    with {:ok, items} <- Chef.cook(recipe) do
      items = Enum.map(items, fn item ->
        Map.put(item, "source", recipe.name)
      end)

      IndexItem.map_apply(items)
    end
  end
end
