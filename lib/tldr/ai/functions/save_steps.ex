defmodule Tldr.AI.Functions.SaveSteps do
  alias LangChain.Function

  alias Tldr.Kitchen

  require Logger

  def new() do
    Function.new!(%{
      name: "save_steps",
      description:
        "Save the steps of a recipe once to the database. This should be called after the steps have been confirmed.",
      parameters_schema: %{
        type: "object",
        properties: %{
          steps: %{
            type: "array",
            description: "Array of steps to execute",
            items: %{
              type: "object",
              properties: %{
                id: %{
                  type: "string",
                  format: "uuid",
                  description: "Unique identifier for the step"
                },
                index: %{
                  type: "integer",
                  description:
                    "Index of the step in the recipe. 0 is first. -1 forces the step to be last."
                },
                name: %{
                  type: "string",
                  description: "Name of the step"
                },
                action: %{
                  type: "string",
                  description: "Type of the step"
                },
                params: %{
                  type: "object",
                  description: "Parameters for the step. Contents vary based on the type.",
                  additionalProperties: true
                }
              },
              required: ["id", "index", "type", "params"],
              additionalProperties: false
            },
            minItems: 1
          }
        },
        required: ["steps"],
        additionalProperties: false
      },
      function: fn args, %{recipe_id: recipe_id, scope: scope} ->
        raw_steps = Map.get(args, "steps", [])

        Logger.debug("Saving #{length(raw_steps)} steps for recipe #{recipe_id}")

        if length(raw_steps) == 0 do
          {:error, "No steps to save."}
        else
          recipe = Kitchen.get_recipe!(scope, recipe_id)
          params = %{steps: raw_steps}

          case Kitchen.update_recipe(scope, recipe, params) do
            {:ok, _recipe} ->
              TldrWeb.PubSub.broadcast("recipe:#{recipe_id}", {:recipe, :reload})
              {:ok, "SUCCESS"}

            {:error, %Ecto.Changeset{} = _changeset} ->
              {:error, "Error saving steps."}
          end
        end
      end
    })
  end
end
