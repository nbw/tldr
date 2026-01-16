defmodule Tldr.Formats.Rss.RssObject do
  use Tldr.Core.EmbeddedEctoSchema

  embedded_schema do
    # field :categories
    # field :cloud
    # field :copyright
    field :description, :string
    # field :docs
    # field :dublin_core_ext
    # field :extensions
    # field :generator
    # field :itunes_ext
    field :language, :string
    # field :last_build_date,
    field :link, :string
    # field :managing_editor
    # field :namespaces
    # field :pub_date
    # field :rating
    # field :skip_days
    # field :skip_hours
    # field :syndication_ext
    # field :text_input
    field :title, :string
    # field :ttl
    # field :webmaster

    embeds_one :image, Image do
      field :url, :string
      field :title, :string
      field :link, :string
      field :width, :integer
      field :height, :integer
    end

    embeds_many :items, Item do
      field :author, :string
      # field :categories
      field :comments, :string
      field :content, :string
      field :description, :string
      # field :enclosure, :string
      # field :extensions, :string
      field :link, :string
      field :title, :string
      # field :source, :string
      # "pub_date" => "Thu, 13 Nov 2025 18:00:00 -0000",
      field :pub_date, :string
      field :guid, :map
    end
  end
end

defimpl Enumerable, for: Tldr.Formats.Rss.RssObject do
  def count(%{items: items}) do
    {:ok, length(items)}
  end

  def member?(%{items: items}, element) do
    {:ok, element in items}
  end

  def reduce(%{items: items}, acc, fun) do
    Enumerable.List.reduce(items, acc, fun)
  end

  def slice(%{items: items}) do
    {:ok, length(items), &Enumerable.List.slice(items, &1, &2, 1)}
  end
end

defimpl Tldr.Feed.FeedProtocol, for: Tldr.Formats.Rss.RssObject.Item do
  alias Tldr.Formats.Rss.RssObject.Item
  alias Tldr.Feed.Schema.IndexItem
  alias Tldr.Core.DateTime, as: DT

  def apply(%Item{} = item) do
    date =
      case DT.from_rss(item.pub_date) do
        {:ok, datetime} -> datetime
        _ -> nil
      end

    %{
      id: Ecto.UUID.generate(),
      title: item.title,
      url: extract_url(item.link),
      description: item.description,
      date: date
    }
    |> IndexItem.apply()
  end

  defp extract_url(url_string) do
    case Regex.run(~r/href="([^"]+)"/, url_string) do
      [_, url] -> url
      nil -> url_string
    end
  end
end

# defimpl Tldr.Feed.FeedProtocol, for: Tldr.Formats.Rss.RssObject do
#   alias Tldr.Formats.Rss.RssObject
#   alias Tldr.Feed.Schema.IndexItem
#   alias Tldr.Core.DateTime, as: DT

#   def apply(%RssObject{items: items}) do
#     Stream.map(items, fn item ->
#       date =
#         case DT.from_rss(item.pub_date) do
#           {:ok, datetime} -> datetime
#           _ -> nil
#         end

#       %{
#         id: Ecto.UUID.generate(),
#         title: item.title,
#         url: extract_url(item.link),
#         description: item.description,
#         date: date
#       }
#     end)
#     |> IndexItem.map_apply()
#   end

#   defp extract_url(url_string) do
#     case Regex.run(~r/href="([^"]+)"/, url_string) do
#       [_, url] -> url
#       nil -> url_string
#     end
#   end
# end
