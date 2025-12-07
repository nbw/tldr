defmodule Tldr.Feed do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Chef
  alias Tldr.Feed.Schema.IndexItem

  def cook_recipe(%Recipe{} = recipe) do
    with {:ok, items} <- Tldr.Kitchen.Chef.cook(recipe) do
      IndexItem.map_apply(items)
    end
  end
end
