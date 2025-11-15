defmodule Tldr.Adapters.HackerNews.Rss do
  alias Tldr.Parsers.Rss
  @rss_url "https://news.ycombinator.com/rss"

  def index do
    with {:ok, %{body: body}} <- Req.get(@rss_url) do
      Rss.parse(body)
    end
  end
end
