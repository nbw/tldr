defmodule Tldr.AI.Functions.RecipeSteps do
  alias LangChain.Function

  require Logger

  def new() do
    Function.new!(%{
      name: "get_steps",
      description: """
      Get the steps for a recipe from the database. Returns the steps as a list of objects.
      """,
      function: fn _, %{scope: scope, recipe_id: recipe_id} ->
        Logger.debug("Get recipe #{recipe_id}'s steps")

        Tldr.Kitchen.get_recipe!(scope, recipe_id)
        |> Map.fetch!(:steps)
        |> JSON.encode!()
      end
    })
  end
end
