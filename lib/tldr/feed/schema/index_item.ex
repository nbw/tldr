defmodule Tldr.Feed.Schema.IndexItem do
  use Tldr.Core.EmbeddedEctoSchema

  embedded_schema do
    field :title, :string
    field :description, :string
    field :date, Tldr.DateTimeType
    field :photo, :string
    field :url, :string
    field :metadata, :map
    field :source, :string
  end
end
