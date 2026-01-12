defmodule Tldr.AI.Functions.HttpGetTest do
  use Tldr.DataCase

  import Mox

  alias Tldr.AI.Functions.HttpGet
  alias Tldr.Core.HttpClient.Response

  setup :verify_on_exit!

  describe "get/1" do
    test "returns a summary of the response" do
      test_url = "https://example.com/api"

      expect(Tldr.Core.HttpClientMock, :get, fn ^test_url ->
        {:ok,
         %Response{
           status: 200,
           content_type: "application/json",
           url: test_url,
           body: %{"message" => "Hello, World!"}
         }}
      end)

      assert {:ok, summary} = HttpGet.get(test_url)

      assert summary =~ """
             API:
             - status: 200
             - content-type: application/json
             - url: https://example.com/api
             - returned an object.
             Sample:
             ```json
             {\"message\":\"Hello, World!\"}
             ```

             """
    end

    test "returns error when request fails" do
      test_url = "https://example.com/api"

      expect(Tldr.Core.HttpClientMock, :get, fn ^test_url ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = HttpGet.get(test_url)
    end
  end
end
