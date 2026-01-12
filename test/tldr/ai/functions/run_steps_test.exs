defmodule Tldr.AI.Functions.RunStepsTest do
  use Tldr.DataCase

  import Mox

  alias Tldr.AI.Functions.RunStep
  alias Tldr.Kitchen.Step
  alias Tldr.Core.HttpClient.Response

  setup :verify_on_exit!

  describe "run_steps/2" do
    test "returns a summary of all steps executed" do
      test_url = "https://elixirforum.com/latest.json"
      fixture = load_fixture("json/elixir_forum_latest.min.json")

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 200,
           content_type: "application/json; charset=utf-8",
           url: test_url,
           body: fixture
         }}
      end)

      steps = [
        Step.new(%{
          id: "1",
          action: "api",
          index: 0,
          params: %{url: test_url}
        }),
        Step.new(%{
          id: "2",
          action: "formatter",
          index: 1,
          params: %{fields: %{"_index" => "$.topic_list.topics"}}
        }),
        Step.new(%{
          id: "3",
          action: "limit",
          index: 2,
          params: %{"count" => 2}
        }),
        Step.new(%{
          id: "4",
          action: "formatter",
          index: -1,
          params: %{
            fields: %{
              "title" => "$.title",
              "url" => "https://elixirforum.com/t/{{$.slug}}",
              "date" => "$.created_at"
            }
          }
        })
      ]

      assert {:ok, result} = RunStep.run_steps(steps, nil)

      assert Kernel.map_size(result) == 4

      assert %{"1" => one, "2" => two, "3" => three, "4" => four} = result

      assert %Response{status: 200, body: ^fixture} = one
      assert two == get_in(fixture, ["topic_list", "topics"])
      assert three == get_in(fixture, ["topic_list", "topics"]) |> Enum.take(2)

      assert four == [
               %{
                 "date" => "2026-01-09T11:51:39.556Z",
                 "title" => "Elixir v1.19.5 released",
                 "url" => "https://elixirforum.com/t/elixir-v1-19-5-released"
               }
             ]
    end

    test "returns error when a step fails" do
      test_url = "https://elixirforum.com/invalid.json"
      fixture = load_fixture("json/elixir_forum_error.json")

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 404,
           body: fixture,
           url: test_url,
           content_type: "application/json"
         }}
      end)

      steps = [
        Step.new(%{
          id: "1",
          action: "api",
          index: 0,
          params: %{url: test_url}
        }),
        Step.new(%{
          id: "2",
          action: "formatter",
          index: 1,
          params: %{fields: %{"_index" => "$.topic_list.topics"}}
        })
      ]

      assert {:error, :run_error, {:step_failed, %Step{id: "1"}, %Response{status: 404}}} =
               RunStep.run_steps(steps, nil)
    end
  end

  describe "parse_steps/1" do
    test "parses raw step maps into Step structs" do
      raw_steps = [
        %{
          "id" => "abc-123",
          "action" => "api",
          "index" => 0,
          "params" => %{"url" => "https://example.com"}
        },
        %{
          "id" => "def-456",
          "action" => "limit",
          "index" => 1,
          "params" => %{"count" => 5}
        }
      ]

      assert {:ok, steps} = RunStep.parse_steps(raw_steps)
      assert length(steps) == 2

      assert [%Step{id: "abc-123", action: "api"}, %Step{id: "def-456", action: "limit"}] = steps
    end
  end

  describe "summarize_results/2" do
    test_url = "https://elixirforum.com/latest.json"
    fixture = load_fixture("json/elixir_forum_latest.min.json")

    expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
      {:ok,
       %Response{
         status: 200,
         content_type: "application/json; charset=utf-8",
         url: test_url,
         body: fixture
       }}
    end)

    steps =
      [
        Step.new(%{
          id: "1",
          action: "api",
          index: 0,
          params: %{url: test_url}
        }),
        Step.new(%{
          id: "2",
          action: "formatter",
          index: 1,
          params: %{fields: %{"_index" => "$.topic_list.topics"}}
        }),
        Step.new(%{
          id: "3",
          action: "limit",
          index: 2,
          params: %{"count" => 2}
        }),
        Step.new(%{
          id: "4",
          action: "formatter",
          index: -1,
          params: %{
            fields: %{
              "title" => "$.title",
              "url" => "https://elixirforum.com/t/{{$.slug}}",
              "date" => "$.created_at"
            }
          }
        })
      ]
      |> Tldr.Kitchen.Step.hydrate()

    {:ok, results} = RunStep.run_steps(steps, nil)

    RunStep.summarize_results(steps, results)
  end
end
