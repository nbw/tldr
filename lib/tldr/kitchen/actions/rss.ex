defmodule Tldr.Kitchen.Actions.Rss do
  @moduledoc false

  @behaviour Tldr.Kitchen.Action

  use Tldr.Core.EmbeddedEctoSchema

  alias Tldr.Kitchen.Step

  embedded_schema do
  end

  @impl true
  def execute(%Step{actor: %__MODULE__{}}, input, _opts) do
    Tldr.Parsers.Rss.parse(input)
  end

  def execute(_action, _input) do
    {:error, :invalid_input}
  end

  @impl true
  def summary(payload) when is_list(payload) do
    "RSS: returned #{length(payload)} items"
  end

  def summary(_payload) do
    "RSS: error - step input was not a list"
  end
end
