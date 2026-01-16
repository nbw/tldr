defmodule Tldr.AI.Chat do
  @moduledoc """
  Simple chat wrapper around Langchain for conversational AI.

  This module provides a stateless interface for sending messages to Claude
  and receiving responses. The LLMChain maintains conversation history.
  """

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatAnthropic
  alias LangChain.Message
  alias LangChain.Message.ContentPart

  alias Tldr.AI.Functions

  @prompt """
  You are an assistant that builds step pipelines for retrieving and formatting JSON API data.
  Each step's output feeds into the next step.

  ## Step Schema

  | Field  | Type    | Required | Description |
  |--------|---------|----------|-------------|
  | id     | UUID    | Yes      | Use generate_uuid function |
  | index  | integer | Yes      | Execution order (0=first,1=second, etc., -1=last) |
  | locked | boolean | No       | If true, don't modify index or delete |
  | action | string  | Yes      | api, formatter, or limit |
  | params | object  | Yes      | Action-specific (see below) |

  ## Actions

  **api**: Fetch JSON from a URL. Example params:
  ```json
  {"url": "https://api.example.com/data", "method": "GET"}
  ```
  Use `{{val}}` to inject the previous step's output value into the URL:
  ```json
  {"url": "https://api.example.com/items/{{val}}", "method": "GET"}
  ```

  **formatter**: Extract and reshape fields using JSONPath. Example params:
  ```json
  {"fields": {"_index": "$.data.items", "title": "$.name", "url": "$.link"}}
  ```
  - `_index`: Selects an nested array to iterate over (evaluated first).
  - Values can be: JSONPath (`$.field`), constants (`"text"`), or interpolated (`"prefix/{{slug}}"` or `"prefix/{{$.slug}}"`).

  **limit**: Limit result count. Example params:
  ```json
  {"count": 10}
  ```

  ## Step rules
  - each step can implement ONE of the actions above.
  - steps are executed in order by index, least to greatest.

  Example steps:
  ```json
  [{"id":"7256bb07-7fc0-4acb-b1e4-b49066bf7c60","index":0,"title":"API URL","params":{"url":"https://api.example.com/data.json"},"action":"api","locked":true},{"id":"3ad4d363-12e3-49f0-b889-87860eee92e5","index":1,"title": "Topics","params":{"fields":{"_index":"$.results.topics"}},"action":"formatter","locked":false},{"id":"f3dafc0d-d876-416f-9c63-539f53522ff8"","index":2,"title": "Limit","params":{"fields":{"count":10}},"action":"limit","locked":false},{"id":"96ec5083-301c-42f8-a27d-50e25f885a2a","index":-1,"title":"Feed Item","params":{"fields":{"date":"$.created_at","title":"$.title","url":"https://elixirforum.com/t/{{$.slug}}"}},"action":"formatter","locked":true}]
  ```

  ## Process

  1. First, analyze the current steps and use them as a starting point.
  2. Generate steps (use `generate_uuid` for new IDs)
  3. Call `run_step` to test the pipeline
  4. Iterate until results match expectations
  5. Call `save_steps` when confirmed

  ## Rules

  - Keep responses short and succinct.
  - IMPORTANT: Don't modify locked steps' indices.
  - IMPORTANT: The final step MUST be a formatter returning: `title`, `url`, and `date` fields.
  - Only answer questions about building steps. Otherwise reply "I'm sorry, I don't understand."
  - Use `http_get` to test APIs if needed.
  - Don't modify working steps unnecessarily.
  - If something goes wrong, say "Sorry, something went wrong."
  """

  @doc """
  Creates a new LLMChain with Claude as the model.
  """
  def new(scope, recipe_id) do
    %{
      llm:
        ChatAnthropic.new!(%{
          model: "claude-sonnet-4-5"
        }),
      custom_context: %{scope: scope, recipe_id: recipe_id}
    }
    |> LLMChain.new!()
    |> LLMChain.add_messages([
      Message.new_system!(system_prompt(scope, recipe_id))
    ])
    |> LLMChain.add_tools(Functions.GenerateUUID.new())
    |> LLMChain.add_tools(Functions.RecipeSteps.new())
    |> LLMChain.add_tools(Functions.HttpGet.new())
    |> LLMChain.add_tools(Functions.RunStep.new())
    |> LLMChain.add_tools(Functions.SaveSteps.new())
  end

  defp system_prompt(scope, recipe_id) do
    """
    #{@prompt}
    #{current_steps(scope, recipe_id)}
    """
  end

  def current_steps(scope, recipe_id) do
    steps =
      Tldr.Kitchen.get_recipe!(scope, recipe_id)
      |> Map.fetch!(:steps)
      |> JSON.encode!()

    """

    ## Current Steps
    ```json
    #{steps}
    ```
    """
  end

  @doc """
  Sends a user message to the chain and returns the updated chain with the response.

  Returns `{:ok, updated_chain}` on success, `{:error, reason}` on failure.

  ## Example

      iex> chain = Tldr.AI.Chat.new()
      iex> {:ok, chain} = Tldr.AI.Chat.send_message(chain, "Hello!")
      {:ok, %LangChain.Chains.LLMChain{...}}

  ## Streaming Alternative

  To enable streaming responses (tokens appear as they're generated), you would:

  1. Pass a callback function to handle delta messages:

      ```
      def send_message_streaming(chain, content, callback) do
        chain
        |> LLMChain.add_message(Message.new_user!(content))
        |> LLMChain.run(stream: true, callback_fn: callback)
      end
      ```

  2. The callback receives `%LangChain.MessageDelta{}` structs with partial content.

  3. In the LiveView, you'd use `send(self(), {:stream_delta, delta})` in the callback
     to push updates to the UI as they arrive.
  """
  def send_message(chain, content) do
    chain
    |> LLMChain.add_message(Message.new_user!(content))
    |> LLMChain.run(mode: :while_needs_response)
  end

  @doc """
  Extracts the text content from the last message in the chain.
  """
  def get_last_response(chain) do
    case chain.last_message do
      nil -> nil
      message -> ContentPart.content_to_string(message.content)
    end
  end
end
