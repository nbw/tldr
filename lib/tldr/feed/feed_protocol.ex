defprotocol Tldr.Feed.FeedProtocol do
  @moduledoc """
  Maybe a better name is Feeder?
  """

  @doc false
  def apply(struct)
end

defimpl Tldr.Feed.FeedProtocol, for: Map do
  def apply(map) do
    [Tldr.Feed.Schema.IndexItem.apply(map)]
  end
end

# defimpl Tldr.Feed.FeedProtocol, for: Tldr.Formats.Rss.RssObject do
#   def apply(%Tldr.Formats.Rss.RssObject{items: items}) do
#     Enum.map(items, fn item ->
#       %{
#         id: Ecto.UUID.generate(),
#         title: item.title,
#         url: item.link,
#         description: item.description,
#         date: item.pub_date
#       }
#       |> Tldr.Feed.Schema.IndexItem.apply()
#     end)
#   end
# end
