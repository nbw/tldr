defmodule TldrWeb.Live.RecipeLive.PreviewComponent do
  use TldrWeb, :live_component

  import TldrWeb.FeedLive.FeedListComponent

  def mount(socket) do
    socket =
      socket
      |> assign(loaded: false)
      |> assign(items: [])

    {:ok, socket}
  end

  defp list_feed_items(recipe, n) do
    recipe
    |> Tldr.Feed.cook_recipe()
    |> Enum.sort_by(& &1.date, {:desc, Date})
    |> Enum.take(n)
  end

  def handle_event("load-preview", _params, socket) do
    socket =
      socket
      |> assign(:loaded, true)
      |> stream(:items, list_feed_items(socket.assigns.recipe, 5))

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <div class="flex justify-center">
        <.button phx-click="load-preview" phx-target={@myself}>Preview</.button>
      </div>
      <div :if={@loaded}>
        <.feed_list items={@streams.items} />
      </div>
    </div>
    """
  end
end
