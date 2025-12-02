defmodule Tldr.Kitchen.Actions.Limit do
  @moduledoc "Limit number of results"

  @behaviour Tldr.Kitchen.Action

  use Tldr.Core.EmbeddedEctoSchema

  alias Tldr.Kitchen.Step

  embedded_schema do
    field :count, :integer
  end

  @impl true
  def execute(%Step{action: %__MODULE__{} = action}, input) when is_list(input) do
    {:ok, Enum.take(input, action.count)}
  end

  def execute(_action, _input) do
    {:error, :invalid_input}
  end
end
