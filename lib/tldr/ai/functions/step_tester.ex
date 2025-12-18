defmodule Tldr.AI.Functions.StepTester do
  alias LangChain.Function

  require Logger

  def new() do
    Function.new!(%{
      name: "step_tester",
      description: "Test a single 'step' that belongs to a recipe.",
      parameters_schema: %{
        type: "object",
        properties: %{
          input: %{
            description:
              "Input data for the step. If it's the the first step in a sequence then the value is null"
          }
        },
        required: []
      },
      function: fn _, _context ->
        Logger.debug("Generating UUID...")
        {:ok, Ecto.UUID.generate()}
      end
    })
  end
end
