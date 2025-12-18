defmodule Tldr.AI.StepAgent do
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatAnthropic
  # alias LangChain.Function
  alias LangChain.Message
  alias LangChain.Message.ContentPart
  alias Tldr.AI.Functions

  defstruct [:model]

  @prompt """
  You are an assistant that helps build a series of steps.

  The steps are used for retrieving data from various sources online,
  for formatting the returned data, and extracting the relevant information.

  Each step is of the format:
  ...

  Notice that each step has a unique ID.
  ...

  There are a number of step types:

  [ description of each step]

  A step can take in a single record or a list of records.

  An example output is:

  [example output]

  As you are building steps, confirm each step
  before moving onto the next one (there's a function for that)

  When you confirm a step, please save it with the function --
  before moving onto the next step.

  If you need to delete a step...

  If you need to update a step...

  If you need to update all steps...

  The final step must be an extractor that returns a "title", "url" and "date"

  """

  def new() do
    model =
      %{llm: ChatAnthropic.new!(%{model: "claude-sonnet-4-5"})}
      |> LLMChain.new!()
      |> LLMChain.add_tools(Functions.GenerateUUID.new())
      |> LLMChain.add_tools(Functions.HttpGet.new())

    %__MODULE__{model: model}
  end

  def tell(%__MODULE__{model: model}, message) do
    model
    |> LLMChain.add_message(Message.new_system!(message))
  end

  def ask(%__MODULE__{model: model}, message) do
    model =
      model
      |> LLMChain.add_message(Message.new_user!(message))

    %__MODULE__{model: model}
  end

  def run(%__MODULE__{model: model}, opts \\ []) do
    LLMChain.run(model, opts)
  end

  def print_response({:ok, response}) do
    ContentPart.content_to_string(response.last_message.content)
    |> print_assistant()
  end

  def print_response(_), do: print_assistant("Hmm.. something went wrong")

  def print_assistant(msg) do
    IO.puts("\nAssistant: #{msg}")
  end
end
