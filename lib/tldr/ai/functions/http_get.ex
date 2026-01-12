defmodule Tldr.AI.Functions.HttpGet do
  alias LangChain.Function

  require Logger

  alias Tldr.Core.HttpClient

  def new() do
    Function.new!(%{
      name: "http_get",
      description: """
      Make an XHR Http GET request to a url.Useful for testing API's.

      Any returned JSON response body has been minified:
      - arrays/lists are reduced to only the first element
      - strings over 100 characters are truncated to 100 and have "..." appended to the end
      """,
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

        get(url)
      end
    })
  end

  def get(url) do
    Logger.debug("HTTP GET request to #{url}")

    case http_client().get(url) do
      {:ok, response} ->
        {:ok, Tldr.Kitchen.Actions.Api.summary(response)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp http_client do
    Application.get_env(:tldr, :http_client, HttpClient)
  end
end
