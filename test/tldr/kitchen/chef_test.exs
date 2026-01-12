defmodule Tldr.Kitchen.ChefTest do
  use Tldr.DataCase

  import Mox

  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Step
  alias Tldr.Kitchen.Chef

  alias Tldr.Core.HttpClient.Response

  setup :verify_on_exit!

  describe "cook/2" do
    test "processes API + formatter steps to extract and format topics" do
      test_url = "https://elixirforum.com/latest.json"
      fixture = load_fixture("json/elixir_forum_latest.json")

      # Mock the HTTP client to return the fixture data
      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 200,
           content_type: "application/json; charset=utf-8",
           url: test_url,
           body: fixture
         }}
      end)

      recipe = %Recipe{
        steps: [
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
            params: %{"count" => 3}
          }),
          Step.new(%{
            id: "4",
            action: "formatter",
            index: -1,
            params: %{
              fields: %{
                "date" => "$.created_at",
                "title" => "$.title",
                "url" => "https://elixirforum.com/t/{{$.slug}}"
              }
            }
          })
        ]
      }

      assert {:ok, result} = Chef.cook(recipe)

      # Result should be a list of formatted topic items
      assert is_list(result)
      assert length(result) == 3

      # Each item should have the expected keys
      first_item = List.first(result)
      assert Map.has_key?(first_item, "date")
      assert Map.has_key?(first_item, "title")
      assert Map.has_key?(first_item, "url")

      # Verify the first topic matches expected data
      assert first_item["title"] == "Elixir v1.19.5 released"
      assert first_item["date"] == "2026-01-09T11:51:39.556Z"
      assert first_item["url"] == "https://elixirforum.com/t/elixir-v1-19-5-released"
    end

    test "returns error when API returns 404" do
      test_url = "https://elixirforum.com/invalid.json"
      fixture = load_fixture("json/elixir_forum_error.json")

      # Mock the HTTP client to return a 404 error response
      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{status: 404, body: fixture, url: test_url, content_type: "application/json"}}
      end)

      recipe = %Recipe{
        steps: [
          Step.new(%{
            id: "123",
            action: "api",
            index: 0,
            params: %{url: test_url}
          }),
          Step.new(%{
            id: "456",
            action: "formatter",
            index: 1,
            params: %{fields: %{"_index" => "$.topic_list.topics"}}
          })
        ]
      }

      assert {:error,
              {:step_failed, %Step{id: "123"},
               %Response{
                 url: ^test_url,
                 status: 404,
                 content_type: "application/json",
                 body: %{
                   "error_type" => "not_found",
                   "errors" => ["The requested URL or resource could not be found."]
                 }
               }}} = Chef.cook(recipe)
    end

    test "returns error when API returns 200 with HTML content" do
      test_url = "https://elixirforum.com/some-page"
      fixture = load_fixture("json/elixir_forum_error.html")

      # Mock the HTTP client to return HTML instead of JSON
      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 200,
           body: fixture,
           url: test_url,
           content_type: "text/html"
         }}
      end)

      recipe = %Recipe{
        steps: [
          Step.new(%{
            id: "123",
            action: "api",
            index: 0,
            params: %{url: test_url}
          })
        ]
      }

      assert {:error, {:step_failed, %Step{id: "123"}, "Response is not JSON"}} =
               Chef.cook(recipe)
    end

    test "returns error when API returns 404 with HTML content" do
      test_url = "https://elixirforum.com/not-found"
      fixture = load_fixture("json/elixir_forum_error.html")

      # Mock the HTTP client to return 404 with HTML body
      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 404,
           body: fixture,
           url: test_url,
           content_type: "text/html"
         }}
      end)

      recipe = %Recipe{
        steps: [
          Step.new(%{
            id: "123",
            action: "api",
            index: 0,
            params: %{url: test_url}
          })
        ]
      }

      assert {:error,
              {:step_failed, %Step{id: "123"},
               %Response{
                 status: 404,
                 body: body,
                 url: ^test_url,
                 content_type: "text/html"
               }}} =
               Chef.cook(recipe)

      assert is_binary(body)
      assert body =~ "Page Not Found"
    end

    test "returns a summary of all steps" do
      test_url = "https://elixirforum.com/latest.json"
      fixture = load_fixture("json/elixir_forum_latest.json")

      # Mock the HTTP client to return the fixture data
      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 200,
           body: fixture,
           url: test_url,
           content_type: "application/json"
         }}
      end)

      recipe = %Recipe{
        steps: [
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
            params: %{"count" => 3}
          }),
          Step.new(%{
            id: "4",
            action: "formatter",
            index: -1,
            params: %{
              fields: %{
                "date" => "$.created_at",
                "title" => "$.title",
                "url" => "https://elixirforum.com/t/{{$.slug}}"
              }
            }
          })
        ]
      }

      assert {:ok, result} = Chef.cook(recipe, nil, summary: true)

      assert length(result) == 4

      assert [{"1", one}, {"2", two}, {"3", three}, {"4", four}] = result

      assert one == %Response{
               body: fixture,
               status: 200,
               url: test_url,
               content_type: "application/json"
             }

      assert two == get_in(fixture, ["topic_list", "topics"])

      assert three == get_in(fixture, ["topic_list", "topics"]) |> Enum.take(3)

      assert four == [
               %{
                 "date" => "2026-01-09T11:51:39.556Z",
                 "title" => "Elixir v1.19.5 released",
                 "url" => "https://elixirforum.com/t/elixir-v1-19-5-released"
               },
               %{
                 "date" => "2020-02-28T11:11:07.580Z",
                 "title" => "ChromicPDF - PDF generator",
                 "url" => "https://elixirforum.com/t/chromicpdf-pdf-generator"
               },
               %{
                 "date" => "2025-11-19T07:18:07.429Z",
                 "title" => "2026/03/23 - Code BEAM Lite Vancouver",
                 "url" => "https://elixirforum.com/t/2026-03-23-code-beam-lite-vancouver"
               }
             ]
    end
  end
end
