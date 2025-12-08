defmodule Tldr.Kitchen.Chef do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Step

  import TldrWeb.PubSub

  @doc """
  Cooks a recipe by executing each step in order.
  """

  def cook(recipe_or_steps, input \\ nil)

  def cook(%Recipe{steps: steps}, input) do
    cook(steps, input)
  end

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

  def cook_with_monitor([%Step{} = step | steps], channel, input \\ nil) do
    broadcast(channel, {:step, step.id, :loading, %{}})

    with {:ok, output} <- cook(step, input) do
      broadcast(channel, {:step, step.id, :success, output})
      :timer.sleep(2000)
      cook_with_monitor(steps, channel, output)
    else
      {:error, {:step_failed, step, reason}} = error ->
        broadcast(channel, {:step, step.id, :error, reason})

        error
      error -> error
    end
  end

  def cook_with_monitor([], _channel, input) do
    {:ok, input}
  end
end
