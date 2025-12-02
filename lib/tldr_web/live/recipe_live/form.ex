defmodule TldrWeb.RecipeLive.Form do
  use TldrWeb, :live_view

  alias Tldr.Kitchen
  alias Tldr.Kitchen.Recipe

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage recipe records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="recipe-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          options={Recipe.types()}
        />
        <.input field={@form[:url]} type="text" label="Url" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Recipe</.button>
          <.button navigate={return_path(@current_scope, @return_to, @recipe)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    recipe = Kitchen.get_recipe!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Recipe")
    |> assign(:recipe, recipe)
    |> assign(:form, to_form(Kitchen.change_recipe(socket.assigns.current_scope, recipe)))
  end

  defp apply_action(socket, :new, _params) do
    recipe = %Recipe{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Recipe")
    |> assign(:recipe, recipe)
    |> assign(:form, to_form(Kitchen.change_recipe(socket.assigns.current_scope, recipe)))
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    changeset =
      Kitchen.change_recipe(socket.assigns.current_scope, socket.assigns.recipe, recipe_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    save_recipe(socket, socket.assigns.live_action, recipe_params)
  end

  defp save_recipe(socket, :edit, recipe_params) do
    case Kitchen.update_recipe(socket.assigns.current_scope, socket.assigns.recipe, recipe_params) do
      {:ok, recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, recipe)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_recipe(socket, :new, recipe_params) do
    case Kitchen.create_recipe(socket.assigns.current_scope, recipe_params) do
      {:ok, recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, recipe)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _recipe), do: ~p"/recipes"
  defp return_path(_scope, "show", recipe), do: ~p"/recipes/#{recipe}"
end
