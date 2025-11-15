defprotocol Tldr.Feed.FeedProtocol do
  @moduledoc """
  Maybe a better name is Feeder?
  """

  @doc false
  def index(struct)

  @doc false
  def show(struct)
end
