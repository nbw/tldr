defmodule Tldr.Parsers.Rss do
  @moduledoc false

  alias Tldr.Formats.Rss.RssObject

  def parse(rss_string) do
    with {:ok, rss_map} <- FastRSS.parse_rss(rss_string) do
      RssObject.apply(rss_map)
    end
  end
end
