defmodule Tldr.Kitchen.Action do
  @moduledoc """
  Defines a contract for actions.

  Each action must implement the functions in this
  behaviour.
  """
  alias Tldr.Kitchen.Step

  @callback execute(params :: Step.t(), input :: any()) :: {:ok, any()} | {:error, any()}
end
