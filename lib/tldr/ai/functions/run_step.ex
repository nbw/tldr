defmodule Tldr.AI.Functions.RunStep do
  alias LangChain.Function

  require Logger

  def new() do
    Function.new!(%{
      name: "run_step",
      description: """
      Run steps from a recipe.
      Usefully for testing the result of a step.
      The array of steps must include all previous steps in addition to the current step being tested.
      For example, testing step index 2 must include steps 0, 1, and 2.

      Steps must be in order by index, least to greatest.
      """,
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
              required: ["id", "index", "action", "params"],
              additionalProperties: false
            },
            minItems: 1
          }
        },
        required: ["input", "steps"],
        additionalProperties: false
      },
      function: fn args, context ->
        raw_steps =
          Map.get(args, "steps", [])

        input = Map.get(context, "input", "[]") |> Jason.decode!()

        Logger.debug(
          "Running #{length(raw_steps)} steps for recipe #{Map.get(context, :recipe_id)}"
        )

        with {:ok, steps} <- parse_steps(raw_steps),
             {:ok, result} <- run_steps(steps, input),
             {:ok, summary} <- summarize_results(steps, result) do
          {:ok, summary}
        else
          {:error, :parse_error, reason} ->
            Logger.error("Error parsing steps: #{inspect(reason)}")
            {:error, "Error parsing steps."}

          {:error, :run_error, reason} ->
            Logger.error("Error running steps: #{inspect(reason)}")
            {:error, "Error running steps."}
        end
      end
    })
  end

  def parse_steps(steps) do
    Enum.reduce_while(steps, {:ok, []}, fn step, {:ok, acc} ->
      case Tldr.Kitchen.Step.apply(step) do
        {:ok, step} ->
          {:cont, {:ok, [step | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, steps} -> {:ok, Enum.reverse(steps)}
      {:error, reason} -> {:error, :parse_error, reason}
    end
  end

  def run_steps(steps, input) do
    case Tldr.Kitchen.Chef.cook(steps, input, summary: true) do
      {:ok, result} -> {:ok, Map.new(result)}
      {:error, reason} -> {:error, :run_error, reason}
    end
  end

  @spec summarize_results(any(), any()) :: :ok
  def summarize_results(steps, results) do
    {:ok,
     Enum.map(steps, fn step ->
       summary =
         if results[step.id] do
           step.actor.__struct__.summary(results[step.id])
           |> String.replace_trailing("\n", "")
         else
           "Step results not found. Previous step likely failed."
         end

       """
       step: #{step.id}
       #{summary}

       """
     end)
     |> Enum.join("")
     |> String.replace("\n\n\n", "\n\n")}
  end
end
