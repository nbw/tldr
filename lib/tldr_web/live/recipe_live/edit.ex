defmodule TldrWeb.RecipeLive.Edit do
  use TldrWeb, :live_view

  require Logger

  alias Tldr.Kitchen
  alias Tldr.Kitchen.Chef
  alias Tldr.Kitchen.Step
  alias Tldr.Kitchen.Recipe

  alias TldrWeb.RecipeLive.Components.RecipeChat

  import TldrWeb.RecipeLive.FormHelpers

  import TldrWeb.RecipeLive.Components.Step
  import TldrWeb.RecipeLive.Components.Helpers

  import Phoenix.HTML.Form, only: [input_value: 2]

  @impl true

  def mount(%{"id" => id} = params, _session, socket) do
    if connected?(socket) do
      TldrWeb.PubSub.subscribe("recipe:#{id}")
    end

    socket = assign(socket, :return_to, return_to(params["return_to"]))

    {:ok, load_recipe(socket, id)}
  end

  def load_recipe(socket, recipe_id) do
    current_scope = socket.assigns.current_scope

    recipe =
      current_scope
      |> Kitchen.get_recipe!(recipe_id)

    recipe_for_form = decode_params_for_form(recipe)

    form =
      current_scope
      |> Kitchen.change_recipe(recipe_for_form)
      |> to_form()

    socket
    |> assign(:step_statuses, %{})
    |> assign(:recipe, recipe_for_form)
    |> assign(:recipe_type, recipe.type)
    |> assign(:form, form)
    |> assign(:show, %{"workspace" => "steps"})
    |> assign_async(:feed, fn ->
      feed = Tldr.Feed.cook_recipe(recipe)

      {:ok, %{feed: feed}}
    end)
  end

  def async_load_feed(socket, recipe) do
    socket
    |> assign_async(:feed, fn ->
      feed = Tldr.Feed.cook_recipe(recipe)

      {:ok, %{feed: feed}}
    end)
  end

  @impl true
  def handle_event("step-" <> step_event_name, param, socket) do
    [step, event_name] = String.split(step_event_name, ":")
    step_component = get_step_component(step)

    # Suppress compiler warning about undefined handle_event (it's provided by macro, but Elixir can't see it at compile time)
    # The most idiomatic approach is to use `@dialyzer {:nowarn_function handle_event: 3}` in the implementation module,
    # but since we don't control all component modules, wrap in a try/catch and document the intent:
    try do
      step_component.handle_event(event_name, param, socket)
    rescue
      UndefinedFunctionError ->
        # This should not happen if macro injected the function, but if not found, log an error
        Logger.error(
          "handle_event/3 not implemented for #{inspect(step_component)}. (This just silences a compile warning if resolved at runtime.)"
        )

        {:noreply, socket}
    end
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
    transformed_params = encode_params_for_save(recipe_params)

    save_recipe(socket, transformed_params)
  end

  @impl true
  def handle_event("add_step", _params, socket) do
    changeset = socket.assigns.form.source

    existing_steps = Ecto.Changeset.get_field(changeset, :steps, [])

    # Split the steps list into those with index >= 0 and those with index < 0
    {positive_steps, negative_steps} =
      Enum.split_with(existing_steps, fn step ->
        index = Map.get(step, :index, 0)
        index >= 0
      end)

    current_index =
      positive_steps
      |> Enum.map(fn step -> Map.get(step, :index, 0) end)
      |> Enum.max()

    new_step = Step.new(%{index: current_index + 1})

    new_changeset =
      Ecto.Changeset.put_embed(
        changeset,
        :steps,
        positive_steps ++ [new_step] ++ negative_steps
      )

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

  @impl true
  def handle_event("preview", %{"id" => id}, socket) do
    recipe = socket.assigns.recipe

    steps =
      socket.assigns.form
      |> input_value(:steps)
      |> Enum.map(fn
        %Ecto.Changeset{} = ch ->
          Ecto.Changeset.apply_action!(ch, :apply)
          |> Map.from_struct()
          |> encode_transform_step_params()
          |> Step.apply!()

        step ->
          step
          |> Map.from_struct()
          |> encode_transform_step_params()
          |> Step.apply!()
      end)

    preview_steps =
      Enum.reduce_while(steps, [], fn
        %{id: step_id} = step, acc when step_id == id ->
          {:halt, [step | acc]}

        step, acc ->
          {:cont, [step | acc]}
      end)
      |> Enum.reverse()

    Task.start(fn ->
      Enum.each(preview_steps, fn step ->
        TldrWeb.PubSub.broadcast("recipe:#{recipe.id}", {:step, step.id, :loading, %{}})
      end)

      Chef.cook(preview_steps, nil, monitor: "recipe:#{recipe.id}")
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_show", params, socket) do
    {:noreply, assign(socket, :show, Map.merge(socket.assigns.show, params))}
  end

  @impl true
  def handle_info({:step, step_id, status, payload}, socket) do
    step_statuses =
      socket.assigns.step_statuses
      |> Map.put(step_id, %{status: status, preview: payload})

    {:noreply, assign(socket, step_statuses: step_statuses)}
  end

  def handle_info({:recipe, :reload}, socket) do
    {:noreply, load_recipe(socket, socket.assigns.recipe.id)}
  end

  defp save_recipe(socket, recipe_params) do
    case Kitchen.update_recipe(socket.assigns.current_scope, socket.assigns.recipe, recipe_params) do
      {:ok, _recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def disable_save?(form) do
    Phoenix.HTML.Form.input_value(form, :type) == nil
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path(_scope, "index", _recipe), do: ~p"/recipes"
  defp return_path(_scope, "show", recipe), do: ~p"/recipes/#{recipe}"
end
