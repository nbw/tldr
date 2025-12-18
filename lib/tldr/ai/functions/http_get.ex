defmodule Tldr.AI.Functions.HttpGet do
  alias LangChain.Function

  require Logger

  def new() do
    Function.new!(%{
      name: "http_get",
      description:
        "Make an XHR Http GET request to a url. Returns the response body. Useful for testing API's.",
      parameters_schema: %{
        type: "object",
        properties: %{
          url: %{
            type: "string",
            description: "The URL to fetch data from"
          }
        },
        required: ["url"]
      },
      function: fn %{"url" => url}, _context ->
        Logger.debug("HTTP GET request to #{url}")

        case Req.get(url) do
          {:ok, response} -> {:ok, JSON.encode!(response.body)}
          {:error, error} -> {:error, error}
        end
      end
    })
  end
end
