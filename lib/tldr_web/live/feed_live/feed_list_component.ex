defmodule TldrWeb.FeedLive.FeedListComponent do
  use TldrWeb, :html

  alias Tldr.Core.DateTime, as: DT

  def feed_list(assigns) do
    ~H"""
    <.async_result :let={items} assign={@items}>
      <:loading>
        <p>Loading...</p>
      </:loading>
      <:failed :let={_reason}>
        <p>Failed to load. Please try again.</p>
      </:failed>
      <.table
        id="feed"
        rows={items}
      >
        <:col :let={item} label="">{format_date(item.date)}</:col>
        <:col :let={item} label="Title">
          <a class="font-semibold hover:underline" href={item.url} target="_blank">
            {item.title}
          </a>
        </:col>
      </.table>
    </.async_result>
    """
  end

  def format_date(date) do
    DT.format_datetime(date, "%Y-%m-%d %H:%M")
  end
end
