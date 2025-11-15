defmodule Tldr.Feed.Schema.IndexItem do
  use Tldr.Core.EmbeddedEctoSchema

  embedded_schema do
    field :title, :string
    field :description, :string
    field :date, :utc_datetime
    field :photo, :string
    field :url, :string
    field :metadata, :map
  end
end
