defmodule TldrWeb.RecipeLive.New do
  use TldrWeb, :live_view

  alias Tldr.Kitchen
  alias Tldr.Kitchen.Recipe

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        New Recipe
        <:subtitle>Create a new recipe to get started.</:subtitle>
      </.header>
      <div class="max-w-lg mx-auto">
        <%= if @recipe_type do %>
          <.new_form form={@form} recipe={@recipe} />
        <% else %>
          <.type_picker />
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def new_form(assigns) do
    ~H"""
    <div class="p-4">
      <.form for={@form} id="recipe-form" phx-change="validate" phx-submit="save">
        <div class="flex flex-col gap-2">
          <.input field={@form[:type]} type="hidden" class="m-0" />
          <div class="border border-gray-500/50 p-2 mx-auto w-full max-w-[10rem]">
            <.type_item type={@recipe.type} />
          </div>
          <div>
            <.input field={@form[:name]} type="text" label="Name" />
          </div>
          <div>
            <.input field={@form[:url]} type="text" label="URL" />
            <p class="text-xs text-gray-500 mb-4">* used for retrieving logos, etc..</p>
          </div>
        </div>
        <footer class="mt-4 text-center">
          <.button phx-disable-with="Saving..." variant="primary">
            Create
          </.button>
        </footer>
      </.form>
    </div>
    """
  end

  def type_picker(assigns) do
    ~H"""
    <div class={[
      "flex flex-col mx-auto divide-y divide-gray-500/50",
      "border border-gray-500/50 w-full max-w-[10rem] mx-auto"
    ]}>
      <div
        :for={type <- Recipe.types()}
        class="p-2"
        phx-click="select-recipe-type"
        phx-value-type={type}
      >
        <.type_item type={type} />
      </div>
    </div>
    """
  end

  attr :type, :string, required: true

  def type_item(assigns) do
    ~H"""
    <div class="flex items-center gap-2 justify-around">
      <.square />
      <span class="uppercase">
        {@type}
      </span>
      <span></span>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    if connected?(socket) do
      Kitchen.subscribe_recipes(current_scope)
    end

    socket = new_recipe(socket)

    {:ok, socket}
  end

  defp new_recipe(socket) do
    current_scope = socket.assigns.current_scope

    recipe = %Recipe{id: Ecto.UUID.generate(), user_id: current_scope.user.id}

    socket
    |> assign(:recipe, recipe)
    |> assign(:recipe_type, nil)
    |> assign(:form, to_form(Kitchen.change_recipe(current_scope, recipe)))
  end

  @impl true
  def handle_event("select-recipe-type", %{"type" => type}, socket) do
    %{
      current_scope: current_scope,
      recipe: recipe
    } = socket.assigns

    changeset = Kitchen.change_recipe(current_scope, recipe, %{type: type})

    {:noreply,
     assign(
       socket,
       recipe: %{recipe | type: type},
       form: to_form(changeset, action: :validate),
       recipe_type: type
     )}
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    %{
      current_scope: current_scope,
      recipe: recipe
    } = socket.assigns

    changeset = Kitchen.change_recipe(current_scope, recipe, recipe_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    default_steps =
      recipe_params["type"]
      |> Kitchen.default_steps()
      |> Enum.map(&Map.from_struct/1)

    recipe_params = Map.put(recipe_params, "steps", default_steps)

    case Kitchen.create_recipe(socket.assigns.current_scope, recipe_params) do
      {:ok, recipe} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/recipes/#{recipe}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
