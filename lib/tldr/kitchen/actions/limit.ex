defmodule Tldr.Kitchen.Actions.Limit do
  @moduledoc "Limit number of results"

  @behaviour Tldr.Kitchen.Action

  use Tldr.Core.EmbeddedEctoSchema

  alias Tldr.Kitchen.Step

  @primary_key false
  embedded_schema do
    field :count, :integer
  end

  @impl true
  def execute(%Step{actor: %__MODULE__{count: count} = action}, input, _opts)
      when is_list(input) and is_number(count) do
    {:ok, Enum.take(input, action.count)}
  end

  def execute(_action, _input, _opts) do
    {:error, :invalid_input}
  end

  @impl true
  def summary(payload) when is_list(payload) do
    "Limit: returned #{length(payload)} items"
  end

  def summary(_payload) do
    "Limit: error - step input was not a list"
  end
end
