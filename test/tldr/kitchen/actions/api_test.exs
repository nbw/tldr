defmodule Tldr.Kitchen.Actions.ApiTest do
  use Tldr.DataCase

  import Mox

  alias Tldr.Kitchen.Actions.Api
  alias Tldr.Kitchen.Step
  alias Tldr.Core.HttpClient.Response

  setup :verify_on_exit!

  describe "execute/3 with GET method" do
    test "returns response when status is 200 with JSON content-type" do
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

      step = build_api_step(test_url)

      assert {:ok, %Response{status: 200, body: body}} = Api.execute(step, nil, [])
      assert body == fixture
      assert get_in(body, ["topic_list", "topics"]) |> length() == 1
    end

    test "substitutes {{val}} placeholder in URL with input value" do
      base_url = "https://example.com/api/{{val}}/details"
      expected_url = "https://example.com/api/123/details"

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^expected_url, _opts ->
        {:ok,
         %Response{
           status: 200,
           content_type: "application/json",
           url: expected_url,
           body: %{"id" => 123}
         }}
      end)

      step = build_api_step(base_url)

      assert {:ok, %Response{body: %{"id" => 123}}} = Api.execute(step, 123, [])
    end

    test "substitutes {{val}} with string input" do
      base_url = "https://example.com/search?q={{val}}"
      expected_url = "https://example.com/search?q=elixir"

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^expected_url, _opts ->
        {:ok,
         %Response{
           status: 200,
           content_type: "application/json",
           url: expected_url,
           body: %{"results" => []}
         }}
      end)

      step = build_api_step(base_url)

      assert {:ok, %Response{body: %{"results" => []}}} = Api.execute(step, "elixir", [])
    end

    test "returns error when response is 200 but not JSON content-type" do
      test_url = "https://elixirforum.com/page"

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 200,
           content_type: "text/html; charset=utf-8",
           url: test_url,
           body: "<html>Not JSON</html>"
         }}
      end)

      step = build_api_step(test_url)

      assert {:error, "Response is not JSON"} = Api.execute(step, nil, [])
    end

    test "returns error response for 4xx status codes" do
      test_url = "https://elixirforum.com/invalid.json"
      fixture = load_fixture("json/elixir_forum_error.json")

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 404,
           content_type: "application/json",
           url: test_url,
           body: fixture
         }}
      end)

      step = build_api_step(test_url)

      assert {:error, %Response{status: 404, body: body}} = Api.execute(step, nil, [])
      assert body["error_type"] == "not_found"
    end

    test "returns error for 400 Bad Request" do
      test_url = "https://example.com/api"

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 400,
           content_type: "application/json",
           url: test_url,
           body: %{"error" => "Bad Request"}
         }}
      end)

      step = build_api_step(test_url)

      assert {:error, %Response{status: 400}} = Api.execute(step, nil, [])
    end

    test "returns error response for 5xx status codes" do
      test_url = "https://example.com/api"

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:ok,
         %Response{
           status: 500,
           content_type: "application/json",
           url: test_url,
           body: %{"error" => "Internal Server Error"}
         }}
      end)

      step = build_api_step(test_url)

      assert {:error, %Response{status: 500}} = Api.execute(step, nil, [])
    end

    test "returns error when http client fails" do
      test_url = "https://example.com/api"

      expect(Tldr.Core.HttpClientMock, :get_cached, fn ^test_url, _opts ->
        {:error, :timeout}
      end)

      step = build_api_step(test_url)

      assert {:error, :timeout} = Api.execute(step, nil, [])
    end
  end

  describe "execute/3 with list input" do
    test "processes each item in the list when index != 0" do
      base_url = "https://example.com/api/{{val}}"

      expect(Tldr.Core.HttpClientMock, :get_cached, 3, fn url, _opts ->
        id =
          url
          |> String.split("/")
          |> List.last()
          |> String.to_integer()

        {:ok,
         %Response{
           status: 200,
           content_type: "application/json",
           url: url,
           body: %{"id" => id, "name" => "Item #{id}"}
         }}
      end)

      step = build_api_step(base_url, index: 1)
      input = [1, 2, 3]

      assert {:ok, results} = Api.execute(step, input, [])
      assert length(results) == 3

      # Results are accumulated in reverse order due to reduce
      assert Enum.any?(results, &(&1.body["id"] == 1))
      assert Enum.any?(results, &(&1.body["id"] == 2))
      assert Enum.any?(results, &(&1.body["id"] == 3))
    end

    test "halts processing when one item fails with error and step_id" do
      base_url = "https://example.com/api/{{val}}"

      # First call succeeds, second fails
      expect(Tldr.Core.HttpClientMock, :get_cached, fn "https://example.com/api/1", _opts ->
        {:ok,
         %Response{
           status: 200,
           content_type: "application/json",
           url: "https://example.com/api/1",
           body: %{"id" => 1}
         }}
      end)

      expect(Tldr.Core.HttpClientMock, :get_cached, fn "https://example.com/api/2", _opts ->
        {:ok,
         %Response{
           status: 404,
           content_type: "application/json",
           url: "https://example.com/api/2",
           body: %{"error" => "Not found"}
         }}
      end)

      step = build_api_step(base_url, index: 1)
      input = [1, 2, 3]

      assert {:error, %Response{status: 404}} = Api.execute(step, input, [])
    end

    test "halts processing when one item fails with simple error" do
      base_url = "https://example.com/api/{{val}}"

      expect(Tldr.Core.HttpClientMock, :get_cached, fn "https://example.com/api/1", _opts ->
        {:ok,
         %Response{
           status: 200,
           content_type: "text/html",
           url: "https://example.com/api/1",
           body: "<html></html>"
         }}
      end)

      step = build_api_step(base_url, index: 1)
      input = [1, 2]

      assert {:error, "Response is not JSON"} = Api.execute(step, input, [])
    end

    test "returns empty list when input is empty list" do
      step = build_api_step("https://example.com/api", index: 1)

      assert {:ok, []} = Api.execute(step, [], [])
    end
  end

  describe "summary/1" do
    test "returns summary for response with map body" do
      response = %Response{
        status: 200,
        content_type: "application/json",
        url: "https://example.com/api",
        body: %{"key" => "value"}
      }

      summary = Api.summary(response)

      assert summary =~ "API:"
      assert summary =~ "status: 200"
      assert summary =~ "content-type: application/json"
      assert summary =~ "url: https://example.com/api"
      assert summary =~ "returned an object"
    end

    test "returns summary for response with list body" do
      response = %Response{
        status: 200,
        content_type: "application/json",
        url: "https://example.com/api",
        body: [%{"id" => 1}, %{"id" => 2}, %{"id" => 3}]
      }

      summary = Api.summary(response)

      assert summary =~ "API:"
      assert summary =~ "status: 200"
      assert summary =~ "returned array of 3 items"
    end

    test "returns summary for response with binary body" do
      response = %Response{
        status: 200,
        content_type: "text/html",
        url: "https://example.com/page",
        body: "<html>content</html>"
      }

      summary = Api.summary(response)

      assert summary =~ "API:"
      assert summary =~ "error: unexpected input"
    end
  end

  # Helper function to build an API step
  defp build_api_step(url, opts \\ []) do
    index = Keyword.get(opts, :index, 0)

    Step.new(%{
      id: Ecto.UUID.generate(),
      action: "api",
      index: index,
      params: %{url: url, method: "GET"}
    })
  end
end
