defmodule TldrWeb.FeedLive.FeedListComponent do
  use TldrWeb, :html

  alias Tldr.Core.DateTime, as: DT

  def feed_list(assigns) do
    ~H"""
    <.table
      id="feed"
      rows={@items}
    >
      <:col :let={{_id, item}} label="">{format_date(item.date)}</:col>
      <:col :let={{_id, item}} label="Title">
        <a class="font-semibold hover:underline" href={item.url} target="_blank">
          {item.title}
        </a>
      </:col>
    </.table>
    """
  end

  def format_date(date) do
    DT.format_datetime(date, "%Y-%m-%d %H:%M")
  end
end
