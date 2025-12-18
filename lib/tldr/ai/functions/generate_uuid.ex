defmodule Tldr.AI.Functions.GenerateUUID do
  alias LangChain.Function

  require Logger

  def new() do
    Function.new!(%{
      name: "generate_uuid",
      description: "Generate a new UUID",
      parameters_schema: %{
        type: "object",
        properties: %{},
        required: []
      },
      function: fn _, _context ->
        Logger.debug("Generating UUID...")
        {:ok, Ecto.UUID.generate()}
      end
    })
  end
end
