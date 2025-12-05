defmodule Tldr.Kitchen.Chef do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Step

  @doc """
  Cooks a recipe by executing each step in order.
  """
  def cook(%Recipe{steps: steps}) do
    cook(steps)
  end

  def cook(steps, input \\ nil)

  def cook([%Step{} = step | steps], input) do
    with {:ok, output} <- cook(step, input) do
      cook(steps, output)
    end
  end

  def cook(%Step{} = step, input) do
    step = Step.hydrate(step)

    with {:ok, module} <- actor_module(step) do
      module.execute(step, input)
    else
      {:error, reason} -> {:error, {:step_failed, step, reason}}
    end
  end

  def cook([], input) do
    {:ok, input}
  end

  def actor_module(%Step{} = step) do
    case step.actor do
      nil -> {:error, :actor_missing}
      struct -> {:ok, struct.__struct__}
    end
  end
end
