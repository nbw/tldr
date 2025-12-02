defmodule Tldr.Kitchen.Chef do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Step

  def cook(%Recipe{} = recipe) do
    cook(nil, recipe.steps)
  end

  # step through each step,
  # with error handling or report at
  # each step
  def cook(input, [%Step{} = step | steps]) do
    with {:ok, output} <- execute_action(step, input) do
      cook(output, steps)
    end
  end

  def cook(input, []) do
    {:ok, input}
  end

  def execute_action(%Step{} = step, input) do
    with {:ok, module} <- action_module(step) do
      module.execute(step, input)
    end
  end

  def action_module(%Step{} = step) do
    case step.action do
      nil -> {:error, :action_missing}
      struct -> {:ok, struct.__struct__}
    end
  end
end
