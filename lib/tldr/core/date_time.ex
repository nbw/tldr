defmodule Tldr.Core.DateTime do
  @moduledoc false

  @doc """
  Parse typical dates from rss feeds.

  Formats:
  - "Thu, 13 Nov 2025 18:00:00 -0000"
  - "Sat, 15 Nov 2025 11:51:38 GMT"
  """
  @rss_formats [
    "%a, %d %b %Y %T %z",
    "%a, %d %b %Y %T %Z"
  ]
  def from_rss(date_string) do
    @rss_formats
    |> Enum.reduce_while(nil, fn format, date ->
      case parse_strftime(date_string, format) do
        {:ok, datetime} -> {:halt, {:ok, datetime}}
        {:error, _} -> {:cont, date}
      end
    end)
    |> case do
      nil -> {:error, :invalid_date}
      {:ok, datetime} -> {:ok, datetime}
    end
  end

  def format_datetime(datetime, format) do
    Timex.format!(datetime, format, :strftime)
  end

  def parse_strftime(date_string, format) do
    Timex.parse(date_string, format, :strftime)
  end

  @doc """
  Returns a human-readable relative time string like "1s", "5m", "4h", "3d".
  """
  def time_since(datetime) do
    now = Timex.now()
    diff_seconds = Timex.diff(now, datetime, :seconds)

    cond do
      diff_seconds < 60 -> "#{diff_seconds}s"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m"
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)}h"
      true -> "#{div(diff_seconds, 86400)}d"
    end
  end
end
