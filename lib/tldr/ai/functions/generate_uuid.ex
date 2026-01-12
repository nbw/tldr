defmodule Tldr.AI.Functions.GenerateUUID do
  alias LangChain.Function

  require Logger

  def new() do
    Function.new!(%{
      name: "generate_uuid",
      description:
        "Generate one more more new UUIDs. Useful for creating unique IDs for new steps.",
      parameters_schema: %{
        type: "object",
        properties: %{
          count: %{
            type: "integer",
            description: "Number of UUIDs to generate",
            default: 1
          }
        },
        required: []
      },
      function: fn %{"count" => count}, _context ->
        Logger.debug("Generating #{count} UUIDs...")
        uuids = Enum.map(1..count, fn _ -> Ecto.UUID.generate() end)
        {:ok, JSON.encode!(uuids)}
      end
    })
  end
end
