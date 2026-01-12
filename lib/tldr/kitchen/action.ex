defmodule Tldr.Kitchen.Action do
  @moduledoc """
  Defines a contract for actions.

  Each action must implement the functions in this
  behaviour.
  """
  alias Tldr.Kitchen.Step

  @callback execute(step :: Step.t(), input :: any(), opts :: Keyword.t()) ::
              {:ok, any()} | {:error, any()}

  @callback summary(payload :: any()) :: String.t()
end
