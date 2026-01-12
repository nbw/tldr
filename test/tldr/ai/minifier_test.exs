defmodule Tldr.AI.MinifierTest do
  use ExUnit.Case, async: true

  alias Tldr.AI.Minifier

  describe "minify/1" do
    test "reduces lists to only first element" do
      data = %{
        "users" => [
          %{"id" => 1, "name" => "Alice"},
          %{"id" => 2, "name" => "Bob"},
          %{"id" => 3, "name" => "Charlie"}
        ]
      }

      result = Minifier.minify(data)

      assert %{"users" => [%{"id" => 1, "name" => "Alice"}]} = result
    end

    test "handles empty lists" do
      data = %{"users" => []}
      result = Minifier.minify(data)
      assert %{"users" => []} = result
    end

    test "truncates strings over 100 characters" do
      long_string = String.duplicate("a", 150)
      data = %{"description" => long_string}

      result = Minifier.minify(data)

      assert %{"description" => truncated} = result
      # 100 + "..."
      assert String.length(truncated) == 103
      assert String.ends_with?(truncated, "...")
    end

    test "keeps strings under 100 characters unchanged" do
      short_string = "This is a short string"
      data = %{"description" => short_string}

      result = Minifier.minify(data)

      assert %{"description" => ^short_string} = result
    end

    test "handles nested structures" do
      data = %{
        "users" => [
          %{
            "id" => 1,
            "posts" => [
              %{"title" => "First post", "comments" => [%{"text" => "Nice!"}]},
              %{"title" => "Second post"}
            ]
          },
          %{"id" => 2}
        ]
      }

      result = Minifier.minify(data)

      assert %{
               "users" => [
                 %{
                   "id" => 1,
                   "posts" => [
                     %{"title" => "First post", "comments" => [%{"text" => "Nice!"}]}
                   ]
                 }
               ]
             } = result
    end

    test "preserves non-string primitive types" do
      data = %{
        "id" => 123,
        "active" => true,
        "score" => 45.6,
        "metadata" => nil
      }

      result = Minifier.minify(data)

      assert result == data
    end

    test "works with the elixir forum fixture" do
      fixture_path = Path.join([__DIR__, "../../support/fixtures/json/elixir_forum_latest.json"])
      data = File.read!(fixture_path) |> Jason.decode!()

      result = Minifier.minify(data)

      # Should have reduced the users array to 1 item
      assert [_single_user] = result["users"]

      # Original size should be much larger than minified
      original_size = data |> Jason.encode!() |> byte_size()
      minified_size = result |> Jason.encode!() |> byte_size()

      assert minified_size < original_size
    end
  end
end
