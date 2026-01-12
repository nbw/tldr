defmodule TldrWeb.FeedLive.Index do
  use TldrWeb, :live_view

  alias Tldr.Kitchen

  import TldrWeb.FeedLive.FeedListComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app class="bg-mesh" flash={@flash} current_scope={@current_scope}>
      <.logo />
      <div class="max-w-2xl mx-auto">
        <.feed_list items={@items} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Kitchen.subscribe_recipes(socket.assigns.current_scope)
    end

    recipes = list_recipes(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Feed")
     |> assign_async(:items, fn -> {:ok, %{items: list_feed_items(recipes)}} end)}
  end

  defp list_recipes(current_scope) do
    Kitchen.list_recipes(current_scope)
  end

  defp list_feed_items(recipes) do
    recipes
    |> Enum.flat_map(&Tldr.Feed.cook_recipe/1)
    |> Enum.sort_by(& &1.date, {:desc, DateTime})
  end
end
