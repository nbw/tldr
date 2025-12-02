defprotocol Tldr.Feed.FeedProtocol do
  @moduledoc """
  Maybe a better name is Feeder?
  """

  @doc false
  def index(struct)
end
