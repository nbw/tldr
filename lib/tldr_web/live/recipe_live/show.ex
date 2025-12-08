defmodule TldrWeb.RecipeLive.Show do
  use TldrWeb, :live_view

  alias Tldr.Kitchen
  alias TldrWeb.Live.RecipeLive.PreviewComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Recipe {@recipe.id}
        <:subtitle>This is a recipe record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/recipes"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/recipes/#{@recipe}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit recipe
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@recipe.name}</:item>
        <:item title="Type">{@recipe.type}</:item>
        <:item title="Steps">
          <div class="flex flex-col gap-2">
            <div :for={step <- @recipe.steps} class="border">
              {step.title}
            </div>
          </div>
        </:item>
      </.list>
      <.live_component module={PreviewComponent} id={@recipe.id} recipe={@recipe} />
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Kitchen.subscribe_recipes(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Recipe")
     |> assign(:recipe, Kitchen.get_recipe!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Tldr.Kitchen.Recipe{id: id} = recipe},
        %{assigns: %{recipe: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :recipe, recipe)}
  end

  def handle_info(
        {:deleted, %Tldr.Kitchen.Recipe{id: id}},
        %{assigns: %{recipe: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current recipe was deleted.")
     |> push_navigate(to: ~p"/recipes")}
  end

  def handle_info({type, %Tldr.Kitchen.Recipe{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
