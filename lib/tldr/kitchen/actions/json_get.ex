defmodule Tldr.Kitchen.Actions.JsonGet do
  @moduledoc "HTTP Get"

  @behaviour Tldr.Kitchen.Action

  alias Tldr.Kitchen.Step

  use Tldr.Core.EmbeddedEctoSchema

  @primary_key false
  embedded_schema do
    field :url, :string
  end

  @impl true
  def execute(%Step{actor: %__MODULE__{}} = step, input) when is_list(input) do
    Enum.reduce_while(input, {:ok, []}, fn item, {:ok, acc} ->
      case execute(step, item) do
        {:ok, response} -> {:cont, {:ok, [response | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  @impl true
  def execute(%Step{actor: %__MODULE__{} = action}, input) do
    url =
      if String.contains?(action.url, "{{val}}") do
        String.replace(action.url, "{{val}}", to_string(input))
      else
        action.url
      end

    case Req.get(url) do
      {:ok, response} -> {:ok, response.body}
      {:error, error} -> {:error, error}
    end
  end
end
