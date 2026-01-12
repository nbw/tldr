# Formatter Action Examples

The `Formatter` action combines JSONPath extraction, constant strings, and string interpolation.

## Usage Modes

### 1. JSONPath Extraction

Extract values from JSON using JSONPath (patterns starting with `$`):

```elixir
fields = %{
  "topics" => "$.topic_list.topics",
  "first_id" => "$.topics[0].id"
}

input = %{
  "topic_list" => %{
    "topics" => [%{"id" => 1, "title" => "Hello"}]
  }
}

# Result:
# %{
#   "topics" => [%{"id" => 1, "title" => "Hello"}],
#   "first_id" => 1
# }
```

### 2. Constant Strings

Return constant string values (no `$` prefix, no `{{...}}`):

```elixir
fields = %{
  "url" => "https://example.com/latest",
  "type" => "forum_post"
}

# Result:
# %{
#   "url" => "https://example.com/latest",
#   "type" => "forum_post"
# }
```

### 3. String Interpolation - Direct Map Access

Interpolate map values directly using `{{key}}` (without `$`):

```elixir
fields = %{
  "url" => "https://example.com/{{slug}}",
  "full_name" => "{{first_name}} {{last_name}}"
}

input = %{
  "slug" => "hello-world",
  "first_name" => "John",
  "last_name" => "Doe"
}

# Result:
# %{
#   "url" => "https://example.com/hello-world",
#   "full_name" => "John Doe"
# }
```

### 4. String Interpolation - JSONPath

Interpolate using JSONPath with `{{$.path}}` (with `$`):

```elixir
fields = %{
  "url" => "https://forum.example.com/t/{{$.topic.slug}}/{{$.topic.id}}"
}

input = %{
  "topic" => %{
    "id" => 42,
    "slug" => "awesome-discussion"
  }
}

# Result:
# %{
#   "url" => "https://forum.example.com/t/awesome-discussion/42"
# }
```

### 5. Mixed Usage

Combine JSONPath extraction, constant strings, direct access, and JSONPath interpolation:

```elixir
fields = %{
  "id" => "$.topic.id",                               # JSONPath extraction
  "url" => "https://example.com/{{slug}}/{{$.topic.id}}", # Direct + JSONPath interpolation
  "type" => "forum_topic"                             # Constant string
}

input = %{
  "topic" => %{"id" => 42},
  "slug" => "my-post"
}

# Result:
# %{
#   "id" => 42,
#   "url" => "https://example.com/my-post/42",
#   "type" => "forum_topic"
# }
```

### 6. Special `_index` Field

Use `_index` to extract a list first, then process each item:

```elixir
fields = %{
  "_index" => "$.topics",
  "id" => "$.id",
  "url" => "https://example.com/t/{{slug}}"
}

input = %{
  "topics" => [
    %{"id" => 1, "slug" => "first"},
    %{"id" => 2, "slug" => "second"}
  ]
}

# Result (list of processed items):
# [
#   %{"id" => 1, "url" => "https://example.com/t/first"},
#   %{"id" => 2, "url" => "https://example.com/t/second"}
# ]
```

## Real-World Example: Elixir Forum Latest Topics

```elixir
fields = %{
  "_index" => "$.topic_list.topics",
  "id" => "$.id",
  "title" => "$.title",
  "url" => "https://elixirforum.com/t/{{slug}}/{{id}}",
  "author_id" => "$.posters[0].user_id"
}

input = %{
  "topic_list" => %{
    "topics" => [
      %{
        "id" => 123,
        "title" => "How to use GenServers",
        "slug" => "how-to-use-genservers",
        "posters" => [%{"user_id" => 456}]
      }
    ]
  }
}

# Result:
# [
#   %{
#     "id" => 123,
#     "title" => "How to use GenServers",
#     "url" => "https://elixirforum.com/t/how-to-use-genservers/123",
#     "author_id" => 456
#   }
# ]
```

