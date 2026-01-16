defprotocol Tldr.Feed.FeedProtocol do
  @moduledoc """
  Maybe a better name is Feeder?
  """

  @doc false
  def apply(struct)
end

defimpl Tldr.Feed.FeedProtocol, for: Map do
  def apply(map) do
    Tldr.Feed.Schema.IndexItem.apply(map)
  end
end
