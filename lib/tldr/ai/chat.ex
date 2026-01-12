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
  You are an assistant that helps build a series of steps to retrieve data via a JSON API.

  The steps are used for retrieving data from various sources online,
  for formatting the returned data, and extracting the relevant information.

  The output of each step feeds into the next step.

  Each step has the format (JSON Schema format):

  ...
  {
   "type": "object",
   "properties": {
     "id": {
       "type": "string",
       "format": "uuid",
       "description": "Unique identifier for the step".
     },
      "index": {
        "type": "integer",
        "description": "Index of the step in the recipe. 0 is first. -1 forces the step to be last."
      },
      "locked": {
        "type": "boolean",
        "description": "Whether the step is locked. If true, do not modify the index or delete the step. If false, the index can be modified."
      },
     "name": {
       "type": "string",
       "description": "Name of the step (optional)"
     },
     "action": {
       "type": "string",
       "description": "Action of the step"
     },
     "params": {
       "type": "object",
       "description": "Parameters for the step. Contents vary based on the action.",
       "additionalProperties": true
     }
   },
   "required": ["id", "index", "type", "params"],
  }
  ```

  IMPORTANT: steps are evaluated either as a single record or a list of records.

  There are a number of step action types:

  # API

  "api": for retrieving data from a JSON API. The params are:

  ```json
  {
    "url": "https://api.example.com/data",
    "method": "GET"
  }
  ```

  Or you can inject an interpretted value (such as an ID) using a {{val}} variable:

  ```json
  {
    "url": "https://api.example.com/data/{{val}}",
    "method": "GET"
  }
  ```

  # LIMIT

  "limit": for limiting the number of results. The params are:

  ```json
  {
    "url": "https://api.example.com/data",
    "method": "GET"
  }
  ```

  # Formatter

  "formatter": for parsing a JSON object and extracting the desired fields.

  The params has a "fields" attribute which contains key value pairs.

  The value can be:
  - a JSONPath formula
    - example: "$.title"
  - a constant string
    - example: "example"
  - a string interpolation of using a {{value}} structure
    - example 1: "https://example.com/{{slug}}" fetches the "slug" field from the input
    - example 2: "https://example.com/{{$.slug}}" evaluates JSONPath $.slug on the input

  For example:

  ```json
  {
    "fields": {
      "title": "$.title",
      "url": "$.url"
    }
  }
  ```

  There is also a special field called "_index" that is evaluated first.

  So to put it all together, an example input of:

  ```json
  {
    "result": {
      "items":[
        {
          "id": 1,
          "name": "Item 1"
          "post_url": "https://example.com/post/1"
        }
      ]
    }
  }
  ```

  would be parsed with:

  ```json
  {
    "_index": "$.result.items"
    "title": "$.name",
    "url": "$.post_url"
  }
  ```

  or with two steps:

  ```json
  // step 1 params
  {
    "_index": "$.result.items"
  }

  // step 2 params
  {
    "title": "$.name",
    "url": "$.post_url"
  }
  ```

  ---

  # Simple Example

  I want max 10 items from the following API:

  "https://api.example.com" returns a JSON object with the shape:

  ```json
  {
    "result": {
      "items":[
        {
          "id": 1,
          "name": "Item 1"
          "post_url": "https://example.com/post/1"
          "created_at": "2026-01-08T12:50:51.002Z"
        },
        ... // more items
      ]
    }
  }
  ```

  The steps would be:

  ```json
  [
    {
      "id": "{{unique UUID}}"
      "index": 0,
      "action": "api",
      "params": {
        "url": "https://api.example.com"
      }
    },
    {
      "id": "{{unique UUID}}"
      "index": 1,
      "action": "formatter",
      "params":   {
        "fields": {
          "_index": "$.result.items"
        }
      }
    },
    {
      "id": "{{unique UUID}}"
      "index": 2,
      "action": "limit",
      "params": {
        "count": 10
      }
    {
      "id": "{{unique UUID}}"
      "action": "formatter",
      "params": {
        "fields": {
          "title": "$.name",
          "url": "$.post_url",
          "date": "$.created_at"
        }
      }
    }
  ]
  ```

  ---

  # Process

  1. First get the current steps for the recipe (recipe_steps function)
  2. Generate a list of steps
  3. Call the run_step function to get a summary of the steps
  4. Refactor until the result is as expected.
  5. Save the steps once confirmed.

  # RULES / IMPORTANT

  - short and succinct responses are preferred.
  - if a step is locked, do not modify the index.
  - only work on tasks related to building steps. If the question is not related, simlpy reply "I'm sorry, I don't understand."
  - if you need a UUID for a new step, call the "generate_uuid" function. Minimize the number of calls by creating multiple UUIDs at once.
  - if you need to test an API, call the "http_get" function to recieve the response body.
  - IMPORTANT: the final step MUST be an "formatter" step that returns "title", "url" and "date" fields.
  - don't modify a previous step that know you works unless necessary
  - if something goes wrong, please mention "Sorry, something went wrong."
  """

  # 1. generate a list of steps
  # 2. run the steps once to get a summary of the results
  # 3. save the steps once confirmed.

  # - verify each step (using the run_step function) one at a time before moving onto the next step.

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
      Message.new_system!(@prompt)
    ])
    |> LLMChain.add_tools(Functions.GenerateUUID.new())
    |> LLMChain.add_tools(Functions.RecipeSteps.new())
    |> LLMChain.add_tools(Functions.HttpGet.new())
    |> LLMChain.add_tools(Functions.RunStep.new())
    |> LLMChain.add_tools(Functions.SaveSteps.new())
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
