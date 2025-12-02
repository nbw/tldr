defmodule Tldr.TldrTest do
  use Tldr.DataCase

  alias Tldr.Kitchen.Step
  alias Tldr.Kitchen.Actions

  test "HTTP GET" do
    result =
      %{
        action: "json_get",
        title: "Top Story IDs",
        description: "Hacker News Top Stories",
        params: %{
          url: "https://hacker-news.firebaseio.com/v0/topstories.json"
        }
      }
      |> Step.apply()

    assert result ==
             {:ok,
              %Step{
                id: nil,
                action: "json_get",
                title: "Top Story IDs",
                description: "Hacker News Top Stories",
                params: %{url: "https://hacker-news.firebaseio.com/v0/topstories.json"},
                actor: %Actions.JsonGet{
                  url: "https://hacker-news.firebaseio.com/v0/topstories.json"
                },
                steps: []
              }}
  end

  test "Limit" do
    result =
      %{
        action: "limit",
        title: "Grab 50 items",
        description: "Grab 50 items",
        params: %{
          count: 50
        }
      }
      |> Step.apply()

    assert result ==
             {:ok,
              %Step{
                id: nil,
                action: "limit",
                title: "Grab 50 items",
                description: "Grab 50 items",
                params: %{count: 50},
                actor: %Actions.Limit{
                  count: 50
                },
                steps: []
              }}
  end

  test "Map" do
    result =
      %{
        action: "map",
        title: "Map",
        description: "Map",
        params: %{},
        steps: [
          %{
            action: "limit",
            title: "Grab 50 items",
            description: "Grab 50 items",
            params: %{
              count: 50
            }
          }
        ]
      }
      |> Step.apply()

    assert result ==
             {:ok,
              %Step{
                id: nil,
                action: "map",
                title: "Map",
                description: "Map",
                params: %{},
                actor: %Actions.Map{},
                steps: [
                  %Step{
                    id: nil,
                    action: "limit",
                    title: "Grab 50 items",
                    description: "Grab 50 items",
                    params: %{count: 50},
                    actor: %Actions.Limit{
                      count: 50
                    },
                    steps: []
                  }
                ]
              }}
  end

  test "Extract" do
    result =
      %{
        action: "extract",
        title: "Extract",
        description: "Extract",
        params: %{
          fields: %{
            title: "$.title",
            url: "$.url"
          }
        }
      }
      |> Step.apply()

    assert result ==
             {:ok,
              %Step{
                id: nil,
                action: "extract",
                title: "Extract",
                description: "Extract",
                params: %{
                  fields: %{
                    title: "$.title",
                    url: "$.url"
                  }
                },
                actor: %Actions.Extract{
                  fields: %{
                    title: "$.title",
                    url: "$.url"
                  }
                },
                steps: []
              }}
  end

  test "json" do
    steps = [
      %{
        action: "get",
        title: "Top Story IDs",
        meta: %{
          url: "https://hacker-news.firebaseio.com/v0/topstories.json"
        }
      },
      %{
        action: "limit",
        title: "Limit to 3",
        meta: %{
          count: 3
        }
      },
      %{
        action: "map",
        title: "Fetch Each Story",
        # Nested steps that execute for each item
        meta: %{
          steps: [
            %{
              action: "get",
              title: "Story Details",
              meta: %{
                url: "https://hacker-news.firebaseio.com/v0/item/{{val}}.json"
              }
            }
          ]
        }
      },
      %{
        action: "limit",
        title: "Limit to 3",
        meta: %{
          count: 2
        }
      },
      %{
        action: "map",
        title: "Fetch Each Story",
        meta: %{
          steps: [
            %{
              action: "extract",
              title: "Extract Fields",
              meta: %{
                fields: %{
                  title: "$.title",
                  url: "$.url"
                }
              }
            }
          ]
        }
      }
    ]

    Tldr.Stepper.start(steps)
    |> IO.inspect(label: "Stepper Result")
  end
end

defmodule Tldr.Stepper do
  require Logger

  def start(steps) do
    step({:ok, nil}, steps)
  end

  def step({:error, _reason} = error, _) do
    error
  end

  def step(input, [%{action: "extract"} = step | rem_steps]) do
    fields = step.meta.fields

    Enum.reduce_while(fields, %{}, fn {k, v}, acc ->
      case Warpath.query(input, v) do
        {:ok, value} -> {:cont, Map.put(acc, k, value)}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> step(rem_steps)
  end

  def step(input, [%{action: "get"} = step | rem_steps]) do
    url =
      if String.contains?(step.meta.url, "{{val}}") do
        String.replace(step.meta.url, "{{val}}", to_string(input))
      else
        step.meta.url
      end

    Logger.info("Fetching data from #{url}")

    with {:ok, response} <- Req.get(url) do
      step(response.body, rem_steps)
    end
  end

  def step(result, [%{action: "limit"} = step | rem_steps]) do
    Logger.info("Limiting data to #{step.meta.count}")

    result =
      if is_list(result) do
        Enum.take(result, step.meta.count)
      else
        {:error, :not_list}
      end

    step(result, rem_steps)
  end

  def step(top_input, [%{action: "map"} = step | rem_steps]) do
    Enum.map(top_input, fn arg ->
      case step(arg, step.meta.steps) do
        {:error, reason} -> {:error, reason}
        result -> result
      end
    end)
    |> step(rem_steps)
  end

  def step(result, _) do
    result
  end
end
