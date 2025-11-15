defmodule Tldr.Core.DateTime do
  @moduledoc false

  @doc """
  "Thu, 13 Nov 2025 18:00:00 -0000"
  """
  def from_rss(date_string) do
    Timex.parse(date_string, "%a, %d %b %Y %T %z", :strftime)
  end
end
