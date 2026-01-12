defmodule Tldr.Kitchen.Actions.Api do
  @moduledoc "HTTP Get"

  @behaviour Tldr.Kitchen.Action

  alias Tldr.Kitchen.Step
  alias Tldr.Core.HttpClient.Response

  import Tldr.AI.Minifier, only: [minify: 1]

  use Tldr.Core.EmbeddedEctoSchema

  @primary_key false
  embedded_schema do
    field :url, :string
    field :method, :string, default: "GET"
  end

  @impl true
  def execute(%Step{actor: %__MODULE__{}, index: index} = step, input, opts)
      when is_list(input) and index != 0 do
    Enum.reduce_while(input, {:ok, []}, fn item, {:ok, acc} ->
      case execute(step, item, opts) do
        {:ok, response} -> {:cont, {:ok, [response | acc]}}
        {:error, error, step_id} -> {:halt, {:error, error, step_id}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  @impl true
  def execute(%Step{actor: %__MODULE__{method: "GET"} = action}, input, _opts) do
    url =
      if String.contains?(action.url, "{{val}}") do
        String.replace(action.url, "{{val}}", to_string(input))
      else
        action.url
      end

    case http_client().get_cached(url, require_json: true) do
      # TODO: is it necessary to check if the response is JSON?
      {:ok, %{status: 200} = response} ->
        if is_json?(response) do
          {:ok, response}
        else
          {:error, "Response is not JSON"}
        end

      {:ok, %{status: status} = response} when status >= 400 and status < 500 ->
        {:error, response}

      {:ok, %{status: _} = response} ->
        {:error, response}

      {:error, error} ->
        {:error, error}
    end
  end

  defp http_client do
    Application.get_env(:tldr, :http_client, Tldr.Core.HttpClient)
  end

  defp is_json?(%Response{content_type: content_type}) do
    is_binary(content_type) and String.starts_with?(content_type, "application/json")
  end

  @impl true
  def summary(%Response{} = response) do
    """
    API:
    - status: #{response.status}
    - content-type: #{response.content_type}
    - url: #{response.url}
    #{payload_summary(response.body)}
    """
  end

  defp payload_summary(payload) when is_map(payload) do
    """
    - returned an object.
    Sample:
    ```json
    #{JSON.encode!(minify(payload))}
    ```
    """
  end

  defp payload_summary(payload) when is_list(payload) do
    """
    - returned array of #{length(payload)} items."
    Sample:
    ```json
    #{JSON.encode!(minify(payload))}
    ```
    """
  end

  defp payload_summary(payload) when is_binary(payload) do
    "- error: unexpected input. Sample: #{minify(payload)}"
  end
end
