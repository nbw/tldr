defmodule Tldr.Kitchen.Chef do
  @moduledoc false

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Step
  alias Tldr.Core.HttpClient.Response

  import TldrWeb.PubSub

  @doc """
  Cooks a recipe by executing each step in order.
  """

  def cook(recipe_or_steps, input \\ nil, opts \\ [])

  def cook(%Recipe{steps: steps, type: type}, input, opts) do
    opts = Keyword.put(opts, :recipe_type, type)

    cook(steps, input, opts)
  end

  def cook([%Step{} | _] = steps, input, opts) do
    do_cook(steps, input, opts)
  end

  def cook(%Step{} = step, input, opts) do
    do_cook([step], input, opts)
  end

  def cook(_steps, input, _opts) do
    {:ok, input}
  end

  def do_cook([%Step{} = step | steps], input, opts) do
    step = Step.hydrate(step)

    monitor({:step, step.id, :loading, %{}}, opts)

    current_input = previous_step_result(input)

    with {:ok, module} <- actor_module(step),
         {:ok, output} <- module.execute(step, current_input, opts) do
      monitor({:step, step.id, :success, output}, opts)

      next_input = next_input(step, output, input, opts)

      do_cook(steps, next_input, opts)
    else
      {:error, reason} ->
        monitor({:step, step.id, :error, reason}, opts)

        {:error, {:step_failed, step, reason}}
    end
  end

  def do_cook(_, input, opts) when is_list(input) do
    if Keyword.get(opts, :summary, false) do
      {:ok, Enum.reverse(input)}
    else
      {:ok, previous_step_result(input)}
    end
  end

  def do_cook(_, input, opts) do
    input
  end

  def actor_module(%Step{} = step) do
    case step.actor do
      nil -> {:error, :actor_missing}
      struct -> {:ok, struct.__struct__}
    end
  end

  def monitor(payload, opts) do
    if channel = Keyword.get(opts, :monitor) do
      broadcast(channel, payload)
    end
  end

  def previous_step_result([result | _]) do
    case result do
      {_steps, %Response{body: body}} -> body
      %Response{body: body} -> body
      {_steps, result} -> result
      result -> result
    end
  end

  def previous_step_result(_steps) do
    nil
  end

  def next_input(step, current_output, previous_input, opts) do
    if Keyword.get(opts, :summary, false) do
      prev = if is_list(previous_input), do: previous_input, else: []
      [{step.id, current_output} | prev]
    else
      [{step.id, current_output}]
    end
  end
end
