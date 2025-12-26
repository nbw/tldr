defmodule TldrWeb.FeedLive.FeedListComponent do
  use TldrWeb, :html

  alias Tldr.Feed.Schema.IndexItem
  alias Tldr.Core.DateTime, as: DT

  def feed_list(assigns) do
    ~H"""
    <div class="pb-12">
      <.async_result :let={items} assign={@items}>
        <:loading>
          <p>Loading...</p>
        </:loading>
        <:failed :let={_reason}>
          <p>Failed to load. Please try again.</p>
        </:failed>
        <div class="flex gap-2 justify-between my-2">
          <div></div>
          <div>
            <.icon name="hero-list-bullet" class="size-5 opacity-40" />
            <.icon name="hero-square-2-stack" class="size-5 opacity-40" />
            <.icon name="hero-squares-2x2" class="size-5 opacity-40" />
          </div>
        </div>
        <div id="feed" class="flex flex-col gap-4">
          <.feed_card :for={item <- items} item={item} />
        </div>
      </.async_result>
    </div>
    """
  end

  attr :item, IndexItem, required: true

  def feed_card(assigns) do
    ~H"""
    <div class="bg-base-100 shadow-xl p-4 border border-base-content/10 rounded-box">
      <div class="flex justify-between">
        <div class="flex items-center gap-4">
          <.source :if={@item.source && String.length(@item.source) > 0} source={@item.source} />
          <a class="font-semibold text-sm hover:underline" href={@item.url} target="_blank">
            {@item.title}
          </a>
        </div>
        <div class="flex items-center gap-4">
          <p class="text-sm text-base-content/70">{time(@item.date)}</p>
          <.icon_heart class="size-5 opacity-40 fill-none hover:fill-current" />
        </div>
      </div>
    </div>
    """
  end

  def source(assigns) do
    ~H"""
    <div class="invert bg-base-100/90 border border-base-100/90 p-1 text-xs text-base-content/70 font-bold uppercase w-4 h-4 flex items-center justify-center">
      {@source |> String.at(0)}
    </div>
    """
  end

  def time(date) do
    DT.time_since(date)
  end
end
