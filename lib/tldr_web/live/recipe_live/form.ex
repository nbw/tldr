defmodule TldrWeb.RecipeLive.Form do
  use TldrWeb, :live_view

  require Logger

  alias Tldr.Kitchen
  alias Tldr.Kitchen.Chef
  alias Tldr.Kitchen.Step
  alias Tldr.Kitchen.Recipe

  alias TldrWeb.RecipeLive.FormHelpers

  import TldrWeb.RecipeLive.Components.Helpers

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage recipe records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="recipe-form" phx-change="validate" phx-submit="save">
        <%= if @recipe_type do %>
          <div class="text-4xl text-center my-4 uppercase">
            {@recipe_type}
          </div>
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:type]} type="text" label="Type" readonly />
        <% else %>
          <div class="flex justify-around items-center">
            <div
              :for={type <- Recipe.types()}
              class="p-4 hover:bg-gray-100 uppercase text-xl"
              phx-click="select_recipe_type"
              phx-value-type={type}
            >
              {type}
            </div>
          </div>
        <% end %>
        <div :if={@recipe_type}>
          <div>
            <h3 class="font-semibold text-lg my-4">Steps</h3>
            <% step_changesets = Ecto.Changeset.get_field(@form.source, :steps, []) %>
            <% steps_count = length(step_changesets) %>
            <.inputs_for :let={step_form} field={@form[:steps]}>
              <.step_fields
                step_form={step_form}
                step_status={FormHelpers.step_status(@step_statuses, step_form)}
                step_preview={FormHelpers.step_preview(@step_statuses, step_form)}
                parent_name="recipe"
                depth={0}
                is_last={step_form.index == steps_count - 1}
              />
              <div :if={step_form.index < steps_count - 1} class="text-center">
                <.icon name="hero-arrow-down-mini" class="w-5 h-5" />
              </div>
            </.inputs_for>
          </div>
          <div
            :if={@recipe_type not in ~w(rss)a}
            phx-click="add_step"
            class="block border border-emerald-600 bg-emerald-500 rounded p-2 text-white text-center my-8"
          >
            <.icon name="hero-plus-circle" class="w-5 h-5" /> Add step
          </div>
        </div>

        <footer>
          <.button disabled={disable_save?(@form)} phx-disable-with="Saving..." variant="primary">
            Save Recipe
          </.button>
          <.button navigate={return_path(@current_scope, @return_to, @recipe)}>Cancel</.button>
        </footer>
      </.form>

      <div :if={@preview} class="p-5">
        <h1 class="font-semibold text-lg">Preview</h1>
        <pre>
          {inspect(@preview, pretty: true)}
        </pre>
      </div>
    </Layouts.app>
    """
  end

  ############### step stuff
  # Component for rendering a single step with its action-specific params
  defp step_fields(assigns) do
    id = Phoenix.HTML.Form.input_value(assigns.step_form, :id)
    action = Phoenix.HTML.Form.input_value(assigns.step_form, :action)

    assigns =
      assigns
      |> assign(:current_action, action)
      |> assign(:id, id)

    ~H"""
    <div class="border border-gray-300/50 bg-gray-400/10 rounded-sm flex my-1" id={"step-#{id}"}>
      <div class="grow p-4 relative">
        <input type="hidden" name={"#{@parent_name}[steps_sort][]"} value={@step_form.index} />
        <.input field={@step_form[:title]} type="text" label="Step Name" />
        <.input
          field={@step_form[:action]}
          type="select"
          label="Action"
          prompt="Select an action..."
          options={action_options()}
        />
        <.step_params_inputs step_form={@step_form} action={@current_action} />
        <div>
          <div :if={@step_preview && @step_status == :success}>
            <div id={"preview-#{id}-toggle"} class="text-center my-2">
              <div phx-click={
                JS.toggle(to: "#preview-#{id}")
                |> JS.dispatch("highlight-code", to: "#preview-#{id}")
                |> JS.hide(to: "#preview-#{id}-toggle")
              }>
                <.icon name="hero-chevron-down" class="w-5 h-5" />
              </div>
            </div>
            <div
              id={"preview-#{id}"}
              phx-hook="HighlightCode"
              class="max-h-[29rem] max-w-full overflow-scroll hidden"
            >
              <pre class="whitespace-pre-wrap break-words text-xs"><code class="language-elixir">
    {inspect(@step_preview, pretty: true)}
                </code></pre>
              <div class="text-center my-2">
                <div phx-click={
                  JS.toggle(to: "#preview-#{id}")
                  |> JS.show(to: "#preview-#{id}-toggle")
                }>
                  <.icon name="hero-chevron-up" class="w-5 h-5" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="flex flex-col justify-center items-center">
        <div class="border border-gray-300/50 rounded-lg flex flex-col justify-center items-center gap-8 p-2 m-4  h-full max-h-[15rem]">
          <div>
            <%= case @step_status do %>
              <% :loading -> %>
                <div class="flex justify-center">
                  <svg
                    class="size-5 animate-spin text-normal"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    >
                    </path>
                  </svg>
                </div>
              <% :success -> %>
                <div phx-click="preview" phx-value-id={@step_form.data.id}>
                  <.icon
                    name="hero-check-circle text-sm text-emerald-500 opacity-70 hover:opacity-50"
                    class="w-6 h-6"
                  />
                </div>
              <% :error -> %>
                <div>
                  <.icon
                    name="hero-exclamation-circle text-rose-500 text-sm opacity-70"
                    class="w-6 h-6"
                  />
                </div>
              <% _ -> %>
                <div phx-click="preview" phx-value-id={@step_form.data.id}>
                  <.icon name="hero-play-circle opacity-70" class="w-6 h-6 hover:opacity-50" />
                </div>
            <% end %>
          </div>
          <div>
            <.icon name="hero-arrow-up-circle opacity-70" class="w-6 h-6 hover:opacity-50" />
          </div>
          <div>
            <.icon name="hero-arrow-down-circle opacity-70" class="w-6 h-6 hover:opacity-50" />
          </div>
          <div>
            <button
              type="button"
              phx-click="delete_step"
              phx-value-index={step_index(@step_form)}
              class="text-rose-400 hover:text-rose-500"
            >
              <.icon name="hero-trash" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:step_statuses, %{})
     |> assign(:preview, nil)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    current_scope = socket.assigns.current_scope

    recipe =
      current_scope
      |> Kitchen.get_recipe!(id)
      |> FormHelpers.decode_params_for_form()

    if connected?(socket) do
      TldrWeb.PubSub.subscribe("recipe:#{id}")
    end

    form =
      current_scope
      |> Kitchen.change_recipe(recipe)
      |> to_form()

    socket
    |> assign(:page_title, "Edit Recipe")
    |> assign(:recipe, recipe)
    |> assign(:recipe_type, recipe.type)
    |> assign(:form, form)
  end

  defp apply_action(socket, :new, _params) do
    current_scope = socket.assigns.current_scope
    recipe = %Recipe{id: Ecto.UUID.generate(), user_id: current_scope.user.id}

    if connected?(socket) do
      TldrWeb.PubSub.subscribe("recipe:#{recipe.id}")
    end

    socket
    |> assign(:page_title, "New Recipe")
    |> assign(:recipe, recipe)
    |> assign(:recipe_type, recipe.type)
    |> assign(:form, to_form(Kitchen.change_recipe(current_scope, recipe)))
  end

  def get_step_component(step) do
    alias TldrWeb.RecipeLive.Components

    case step do
      "json_get" -> Components.JsonGetStep
      "limit" -> Components.LimitStep
      "extract" -> Components.ExtractStep
      "format" -> Components.FormatStep
      "map" -> Components.MapStep
      _ -> raise "missing step component: #{step}"
    end
  end

  @impl true
  def handle_event("step-" <> step_event_name, param, socket) do
    [step, event_name] = String.split(step_event_name, ":")
    step_component = get_step_component(step)
    step_component.handle_event(event_name, param, socket)
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

  def handle_event("select_recipe_type", %{"type" => type}, socket) do
    %{
      current_scope: current_scope,
      recipe: recipe
    } = socket.assigns

    type = String.to_existing_atom(type)

    recipe = %{recipe | type: type, steps: Recipe.default_steps(type)}

    changeset = Kitchen.change_recipe(current_scope, recipe, %{})

    {:noreply, assign(socket, recipe_type: type, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    transformed_params = FormHelpers.encode_params_for_save(recipe_params)

    save_recipe(socket, socket.assigns.live_action, transformed_params)
  end

  @impl true
  def handle_event("add_step", _params, socket) do
    changeset = socket.assigns.form.source

    existing_steps = Ecto.Changeset.get_field(changeset, :steps, [])

    new_step = Step.new()

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, existing_steps ++ [new_step])

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  def handle_event("delete_step", %{"index" => index}, socket) do
    changeset = socket.assigns.form.source

    existing_steps = Ecto.Changeset.get_field(changeset, :steps, [])

    index = String.to_integer(index)

    updated_steps = List.delete_at(existing_steps, index)

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, updated_steps)

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  def handle_event("preview", %{"id" => id}, socket) do
    recipe = socket.assigns.recipe

    steps =
      socket.assigns.form
      |> Phoenix.HTML.Form.input_value(:steps)
      |> Enum.map(fn
        %Ecto.Changeset{} = ch ->
          Ecto.Changeset.apply_action!(ch, :apply)
          |> Map.from_struct()
          |> FormHelpers.encode_transform_step_params()
          |> Step.apply!()

        step ->
          step
          |> Map.from_struct()
          |> FormHelpers.encode_transform_step_params()
          |> Step.apply!()
      end)

    preview_steps =
      Enum.reduce_while(steps, [], fn
        %{id: step_id} = step, acc when step_id == id ->
          {:halt, [step | acc]}

        %{id: step_id} = step, acc ->
          {:cont, [step | acc]}
      end)
      |> Enum.reverse()

    Task.start(fn ->
      Enum.each(preview_steps, fn step ->
        TldrWeb.PubSub.broadcast("recipe:#{recipe.id}", {:step, step.id, :loading, %{}})
      end)

      Chef.cook_with_monitor(preview_steps, "recipe:#{recipe.id}")
    end)

    # socket = case  do
    #           {:ok, preview} -> assign(socket, :preview, preview)
    #           {:error, error} ->
    #             Logger.error(error)
    #             socket
    #             |> assign(:preview, nil)
    #             |> put_flash(:error, "Failed to preview recipe")
    #          end

    {:noreply, socket}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    save_recipe(socket, socket.assigns.action, recipe_params)
  end

  def handle_info({:step, step_id, status, payload}, socket) do
    step_statuses =
      socket.assigns.step_statuses
      |> Map.put(step_id, %{status: status, preview: payload})

    {:noreply, assign(socket, step_statuses: step_statuses)}
  end

  defp save_recipe(socket, :new, recipe_params) do
    case Kitchen.create_recipe(socket.assigns.current_scope, recipe_params) do
      {:ok, recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe created successfully")
         |> push_navigate(to: ~p"/recipes/#{recipe}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_recipe(socket, :edit, recipe_params) do
    case Kitchen.update_recipe(socket.assigns.current_scope, socket.assigns.recipe, recipe_params) do
      {:ok, _recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")}

      # |> push_navigate(
      #   to: return_path(socket.assigns.current_scope, socket.assigns.return_to, recipe)
      # )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def disable_save?(form) do
    Phoenix.HTML.Form.input_value(form, :type) == nil
  end

  # Dynamic params inputs based on action type
  defp step_params_inputs(%{action: nil} = assigns), do: ~H""
  defp step_params_inputs(%{action: ""} = assigns), do: ~H""

  defp step_params_inputs(%{action: action} = assigns) do
    step_component = get_step_component(action)
    step_component.step_params_inputs(assigns)
  end

  defp action_options do
    [
      {"HTTP GET", "json_get"},
      {"Limit", "limit"},
      {"Extract", "extract"},
      {"Format", "format"}
    ]
  end

  def handle_event("delete_step", %{"index" => index_str}, socket) do
    changeset = socket.assigns.form.source
    index = String.to_integer(index_str)

    existing_steps = Ecto.Changeset.get_field(changeset, :steps, [])
    updated_steps = List.delete_at(existing_steps, index)

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, updated_steps)

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path(_scope, "index", _recipe), do: ~p"/recipes"
  defp return_path(_scope, "show", recipe), do: ~p"/recipes/#{recipe}"
end
