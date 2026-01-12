defmodule Tldr.Kitchen.Actions.FormatterTest do
  use ExUnit.Case, async: true

  alias Tldr.Kitchen.Actions.Formatter
  alias Tldr.Kitchen.Step

  describe "execute/2 with JSONPath extraction" do
    test "extracts values using JSONPath" do
      action = %Formatter{
        fields: %{
          "topics" => "$.topic_list.topics",
          "users" => "$.users"
        }
      }

      step = %Step{actor: action}

      input = %{
        "topic_list" => %{
          "topics" => [%{"id" => 1, "title" => "Hello"}]
        },
        "users" => [%{"id" => 1, "name" => "Alice"}]
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["topics"] == [%{"id" => 1, "title" => "Hello"}]
      assert result["users"] == [%{"id" => 1, "name" => "Alice"}]
    end

    test "extracts nested values" do
      action = %Formatter{
        fields: %{
          "first_topic_id" => "$.topics[0].id",
          "first_topic_title" => "$.topics[0].title"
        }
      }

      step = %Step{actor: action}

      input = %{
        "topics" => [
          %{"id" => 123, "title" => "First Post"},
          %{"id" => 456, "title" => "Second Post"}
        ]
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["first_topic_id"] == 123
      assert result["first_topic_title"] == "First Post"
    end
  end

  describe "execute/2 with string interpolation - direct access" do
    test "interpolates map values directly (without $)" do
      action = %Formatter{
        fields: %{
          "url" => "https://example.com/{{slug}}",
          "title" => "Post: {{title}}"
        }
      }

      step = %Step{actor: action}

      input = %{
        "slug" => "hello-world",
        "title" => "Hello World"
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["url"] == "https://example.com/hello-world"
      assert result["title"] == "Post: Hello World"
    end

    test "handles multiple direct interpolations in one string" do
      action = %Formatter{
        fields: %{
          "message" => "User {{username}} posted '{{title}}' at {{timestamp}}"
        }
      }

      step = %Step{actor: action}

      input = %{
        "username" => "Alice",
        "title" => "My First Post",
        "timestamp" => "2024-01-01"
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["message"] == "User Alice posted 'My First Post' at 2024-01-01"
    end

    test "returns empty string for missing keys" do
      action = %Formatter{
        fields: %{
          "url" => "https://example.com/{{missing}}"
        }
      }

      step = %Step{actor: action}
      input = %{"slug" => "test"}

      assert {:ok, result} = Formatter.execute(step, input)
      # nil converts to empty string
      assert result["url"] == "https://example.com/"
    end
  end

  describe "execute/2 with string interpolation - JSONPath" do
    test "interpolates JSONPath values into strings (with $)" do
      action = %Formatter{
        fields: %{
          "url" => "https://example.com/{{$.slug}}",
          "title" => "Post: {{$.title}}"
        }
      }

      step = %Step{actor: action}

      input = %{
        "slug" => "hello-world",
        "title" => "Hello World"
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["url"] == "https://example.com/hello-world"
      assert result["title"] == "Post: Hello World"
    end

    test "interpolates nested JSONPath values" do
      action = %Formatter{
        fields: %{
          "url" => "https://forum.example.com/t/{{$.topic.slug}}/{{$.topic.id}}"
        }
      }

      step = %Step{actor: action}

      input = %{
        "topic" => %{
          "id" => 42,
          "slug" => "awesome-post"
        }
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["url"] == "https://forum.example.com/t/awesome-post/42"
    end

    test "handles multiple JSONPath interpolations in one string" do
      action = %Formatter{
        fields: %{
          "message" => "User {{$.user.name}} posted '{{$.title}}' at {{$.timestamp}}"
        }
      }

      step = %Step{actor: action}

      input = %{
        "user" => %{"name" => "Alice"},
        "title" => "My First Post",
        "timestamp" => "2024-01-01"
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["message"] == "User Alice posted 'My First Post' at 2024-01-01"
    end
  end

  describe "execute/2 with constant strings" do
    test "returns constant strings unchanged" do
      action = %Formatter{
        fields: %{
          "constant" => "https://example.com/latest",
          "type" => "forum_post"
        }
      }

      step = %Step{actor: action}
      input = %{"other" => "value"}

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["constant"] == "https://example.com/latest"
      assert result["type"] == "forum_post"
    end
  end

  describe "execute/2 with mixed extraction and formatting" do
    test "handles JSONPath extraction, constant strings, and interpolation" do
      action = %Formatter{
        fields: %{
          "topics" => "$.topic_list.topics",
          "url" => "https://example.com/t/{{slug}}",
          "type" => "topic_list"
        }
      }

      step = %Step{actor: action}

      input = %{
        "topic_list" => %{
          "topics" => [%{"id" => 1}]
        },
        "slug" => "my-topic"
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["topics"] == [%{"id" => 1}]
      assert result["url"] == "https://example.com/t/my-topic"
      assert result["type"] == "topic_list"
    end

    test "mixes direct access and JSONPath interpolation" do
      action = %Formatter{
        fields: %{
          "url" => "https://example.com/{{slug}}/{{$.nested.id}}"
        }
      }

      step = %Step{actor: action}

      input = %{
        "slug" => "my-post",
        "nested" => %{"id" => 42}
      }

      assert {:ok, result} = Formatter.execute(step, input)
      assert result["url"] == "https://example.com/my-post/42"
    end
  end

  describe "validation" do
    test "returns error for unmatched opening braces" do
      action = %Formatter{
        fields: %{
          "url" => "https://example.com/{{$.slug"
        }
      }

      step = %Step{actor: action}
      input = %{"slug" => "test"}

      assert {:error, reason} = Formatter.execute(step, input)
      assert reason =~ "Unmatched {{ or }}"
    end

    test "returns error for unmatched closing braces" do
      action = %Formatter{
        fields: %{
          "url" => "https://example.com/{{$.slug}}}}"
        }
      }

      step = %Step{actor: action}
      input = %{"slug" => "test"}

      assert {:error, reason} = Formatter.execute(step, input)
      assert reason =~ "Unmatched {{ or }}"
    end

    test "returns error for mismatched braces" do
      action = %Formatter{
        fields: %{
          "url" => "https://{{example.com/{{$.slug}}"
        }
      }

      step = %Step{actor: action}
      input = %{"slug" => "test"}

      assert {:error, reason} = Formatter.execute(step, input)
      assert reason =~ "Unmatched {{ or }}"
    end
  end

  describe "execute/2 with lists" do
    test "processes each item in a list" do
      action = %Formatter{
        fields: %{
          "title" => "$.title",
          "url" => "https://example.com/{{slug}}"
        }
      }

      step = %Step{actor: action}

      input = [
        %{"title" => "First", "slug" => "first"},
        %{"title" => "Second", "slug" => "second"}
      ]

      assert {:ok, results} = Formatter.execute(step, input)
      assert length(results) == 2
      assert Enum.at(results, 0) == %{"title" => "First", "url" => "https://example.com/first"}
      assert Enum.at(results, 1) == %{"title" => "Second", "url" => "https://example.com/second"}
    end
  end

  describe "execute/2 with _index field" do
    test "extracts index first, then processes remaining fields" do
      action = %Formatter{
        fields: %{
          "_index" => "$.topics",
          "id" => "$.id",
          "url" => "https://example.com/t/{{slug}}"
        }
      }

      step = %Step{actor: action}

      input = %{
        "topics" => [
          %{"id" => 1, "slug" => "hello"},
          %{"id" => 2, "slug" => "world"}
        ]
      }

      assert {:ok, results} = Formatter.execute(step, input)
      assert is_list(results)
      assert length(results) == 2
      assert Enum.at(results, 0) == %{"id" => 1, "url" => "https://example.com/t/hello"}
      assert Enum.at(results, 1) == %{"id" => 2, "url" => "https://example.com/t/world"}
    end
  end

  describe "execute/2 with empty fields" do
    test "returns input unchanged when fields is empty" do
      action = %Formatter{fields: %{}}
      step = %Step{actor: action}
      input = %{"foo" => "bar"}

      assert {:ok, result} = Formatter.execute(step, input)
      assert result == input
    end
  end

  describe "summary/1" do
    test "returns summary with count and first item for non-empty list" do
      payload = [
        %{"id" => 1, "title" => "First"},
        %{"id" => 2, "title" => "Second"}
      ]

      result = Formatter.summary(payload)

      assert result ==
               """
               Formatter: returned 2 items. First item:
               ```json
               {\"id\":1,\"title\":\"First\"}
               ```
               """
    end

    test "returns zero count message for empty list" do
      result = Formatter.summary([])

      assert result =~ "Formatter: returned 0 items."
      refute result =~ "First item:"
    end

    test "returns object keys for map payload" do
      payload = %{"title" => "Hello", "url" => "https://example.com", "id" => 42}

      result = Formatter.summary(payload)

      assert result == """
             Formatter: returned an object, not a list of items. Object keys: id, title, url
             """
    end

    test "returns error message for non-list and non-map payload" do
      assert Formatter.summary("string") == """
             Formatter: error - returned neither a list or map.
             """
    end
  end
end
