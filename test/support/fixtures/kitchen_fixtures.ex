defmodule Tldr.KitchenFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tldr.Kitchen` context.
  """

  @doc """
  Generate a recipe.
  """
  def recipe_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name",
        type: "json",
        url: "some url"
      })

    {:ok, recipe} = Tldr.Kitchen.create_recipe(scope, attrs)
    recipe
  end
end
