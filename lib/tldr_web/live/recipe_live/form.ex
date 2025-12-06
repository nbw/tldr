require IEx

defmodule TldrWeb.RecipeLive.Form do
  alias DialyxirVendored.Formatter.IgnoreFile
  use TldrWeb, :live_view

  alias Tldr.Kitchen
  alias Tldr.Core
  alias Tldr.Kitchen.Step
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
        <div>
          <div>
            <h3 class="font-semibold text-lg">Steps</h3>
            <.inputs_for :let={step_form} field={@form[:steps]}>
              <.step_fields step_form={step_form} parent_name="recipe" depth={0} />
            </.inputs_for>
          </div>
          <div
            phx-click="add_step"
            class="block border border-emerald-600 bg-emerald-500 rounded p-2 text-white text-center"
          >
            <.icon name="hero-plus-circle" class="w-5 h-5" /> Add step
          </div>
        </div>

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

    recipe = decode_params_for_form(recipe)

    form = to_form(Kitchen.change_recipe(socket.assigns.current_scope, recipe))

    socket
    |> assign(:page_title, "Edit Recipe")
    |> assign(:recipe, recipe)
    |> assign(:form, form)
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

  def handle_event("save", %{"recipe" => recipe_params} = params, socket) do
    transformed_params = encode_params_for_save(recipe_params)

    save_recipe(socket, socket.assigns.live_action, transformed_params)
  end

  def handle_event("add_step", _params, socket) do
    changeset = socket.assigns.form.source

    existing_steps =
      changeset
      |> Ecto.Changeset.get_field(:steps, [])

    new_step = %Step{id: Ecto.UUID.generate()}

    new_changeset =
      changeset
      |> Ecto.Changeset.put_embed(:steps, existing_steps ++ [new_step])

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  def handle_event("delete_step", %{"index" => index}, socket) do
    changeset = socket.assigns.form.source

    index = String.to_integer(index)

    existing_steps = Ecto.Changeset.get_field(changeset, :steps, [])

    updated_steps = List.delete_at(existing_steps, index)

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, updated_steps)

    {:noreply, assign(socket, form: to_form(new_changeset))}
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

  ############### step stuff
  # Component for rendering a single step with its action-specific params
  defp step_fields(assigns) do
    action = Phoenix.HTML.Form.input_value(assigns.step_form, :action)
    assigns = assign(assigns, :current_action, action)

    ~H"""
    <div class="border border-gray-300 rounded p-4 relative space-y-3 my-4">
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

      <%!-- Nested steps for "map" action --%>
      <%= if @current_action == "map" do %>
        <div class="ml-4 mt-4 border-l-2 border-emerald-300 pl-4">
          <h4 class="font-medium text-sm text-gray-600 mb-2">Nested Steps</h4>

          <.inputs_for :let={nested_step_form} field={@step_form[:steps]}>
            <.step_fields
              step_form={nested_step_form}
              parent_name={"#{@parent_name}[steps][#{@step_form.index}]"}
              depth={@depth + 1}
            />
          </.inputs_for>

          <button
            type="button"
            phx-click="add_nested_step"
            phx-value-id={step_id(@step_form)}
            phx-value-index={step_index(@step_form)}
            class="block w-full mt-2 border border-emerald-400 bg-emerald-100 rounded p-2 text-emerald-700 text-center text-sm hover:bg-emerald-200"
          >
            <.icon name="hero-plus-circle" class="w-4 h-4" /> Add nested step
          </button>
        </div>
      <% end %>

      <button
        type="button"
        phx-click="delete_step"
        phx-value-index={step_index(@step_form)}
        class="absolute top-2 right-2 text-red-600 hover:text-red-800"
      >
        <.icon name="hero-trash" class="w-5 h-5" />
      </button>
    </div>
    """
  end

  # Dynamic params inputs based on action type
  defp step_params_inputs(%{action: nil} = assigns), do: ~H""
  defp step_params_inputs(%{action: ""} = assigns), do: ~H""

  defp step_params_inputs(%{action: "limit"} = assigns) do
    ~H"""
    <div class="bg-gray-50 p-3 rounded">
      <.input
        name={"#{@step_form.name}[params][count]"}
        value={get_param_value(@step_form, "count")}
        type="number"
        label="Count"
        min="1"
      />
    </div>
    """
  end

  defp step_params_inputs(%{action: "json_get"} = assigns) do
    ~H"""
    <div class="bg-gray-50 p-3 rounded">
      <.input
        name={"#{@step_form.name}[params][url]"}
        value={get_param_value(@step_form, "url")}
        type="text"
        label="URL"
        placeholder="https://api.example.com/data or use {{val}} for interpolation"
      />
    </div>
    """
  end

  defp step_params_inputs(%{action: "map"} = assigns) do
    ~H"""
    <p class="text-sm text-gray-500 italic">
      Map iterates over each item and applies the nested steps below.
    </p>
    """
  end

  defp step_params_inputs(%{action: "extract"} = assigns) do
    ~H"""
    <div class="bg-gray-50 p-3 rounded">
      <p class="text-sm text-gray-600 mb-3">
        Extract fields from the input data using JSON paths.
      </p>

      <div class="space-y-2 mb-3">
        <% fields = get_extract_fields(@step_form) %>
        <%= if fields == [] do %>
          <p class="text-sm text-gray-500 italic">No fields configured yet.</p>
        <% else %>
          <div :for={{idx, %{"key" => key, "value" => value}} <- fields}>
            <div class="flex gap-2 items-center bg-white p-2 rounded border border-gray-200">
              <input
                type="text"
                name={"#{@step_form.name}[params][fields][#{idx}][key]"}
                value={key}
                placeholder="Field name"
                class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
              />
              <span class="text-gray-400">→</span>
              <input
                type="text"
                name={"#{@step_form.name}[params][fields][#{idx}][value]"}
                value={value}
                placeholder="JSON path (e.g., $.title)"
                class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
              />
              <button
                type="button"
                phx-click="remove_extract_field"
                phx-value-path={step_index(@step_form)}
                phx-value-key={key}
                class="text-red-600 hover:text-red-800 text-sm"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </button>
            </div>
          </div>
        <% end %>
      </div>

      <button
        type="button"
        phx-click="add_extract_field"
        phx-value-id={step_id(@step_form)}
        phx-value-index={step_index(@step_form)}
        class="block w-full border border-emerald-400 bg-emerald-100 rounded p-2 text-emerald-700 text-center text-sm hover:bg-emerald-200"
      >
        <.icon name="hero-plus-circle" class="w-4 h-4" /> Add field
      </button>
    </div>
    """
  end

  defp step_params_inputs(assigns), do: ~H""

  # Helper to get extract fields from a step
  defp get_extract_fields(step_form) do
    params = Phoenix.HTML.Form.input_value(step_form, :params) || %{}
    fields = Map.get(params, :fields) || Map.get(params, "fields") || %{}

    # Convert to list of tuples for iteration
    case fields do
      map when is_map(map) -> Map.to_list(map)
      _ -> []
    end
  end

  # Helper to get param value - checks both form params and data
  defp get_param_value(step_form, key) do
    string_key = to_string(key)
    atom_key = if is_binary(key), do: String.to_existing_atom(key), else: key

    # Check form params first (what user has entered)
    from_params = get_in(step_form.params || %{}, ["params", string_key])

    if from_params do
      from_params
    else
      # Fall back to data value
      params = Phoenix.HTML.Form.input_value(step_form, :params) || %{}
      Map.get(params, atom_key) || Map.get(params, string_key)
    end
  rescue
    # String.to_existing_atom failed
    ArgumentError -> nil
  end

  # Helper to build input names for nested params
  defp input_name(form, path) do
    base = Phoenix.HTML.Form.input_name(form, :params)

    path
    |> Enum.reduce(base, fn
      key, acc when is_atom(key) -> "#{acc}[#{key}]"
      key, acc when is_integer(key) -> "#{acc}[#{key}]"
      key, acc -> "#{acc}[#{key}]"
    end)
  end

  # Helper to get param value from form
  defp get_param_value(form, key) do
    params = Phoenix.HTML.Form.input_value(form, :params) || %{}

    case params do
      %{^key => value} ->
        value

      %{} ->
        # Try string key
        string_key = to_string(key)
        Map.get(params, string_key)

      _ ->
        nil
    end
  end

  defp step_id(form) do
    case form.source do
      %Ecto.Changeset{data: %{id: id}} when is_binary(id) and byte_size(id) > 0 -> "#{id}"
      %Ecto.Changeset{changes: %{id: id}} when is_binary(id) and byte_size(id) > 0 -> "#{id}"
      _ -> nil
    end
  end

  # Build a path string for identifying nested steps
  defp step_index(form) do
    # This creates a path like "0" or "0.steps.1" for nested steps
    case form.source do
      %Ecto.Changeset{} -> "#{form.index}"
      _ -> ""
    end
  end

  defp action_options do
    [
      {"JSON GET", "json_get"},
      {"Limit", "limit"},
      {"Extract", "extract"},
      {"Map", "map"}
    ]
  end

  def handle_event("add_nested_step", %{"id" => id}, socket) do
    # Add step nested under another step
    changeset = socket.assigns.form.source

    steps = Ecto.Changeset.get_field(changeset, :steps, [])
    index = Enum.find_index(steps, &(&1.id == id))
    step = Enum.at(steps, index)

    new_nested_step = %Step{id: Ecto.UUID.generate()}
    updated_step = %{step | steps: (step.steps || []) ++ [new_nested_step]}
    updated_steps = List.replace_at(steps, index, updated_step)

    new_changeset =
      changeset
      |> Ecto.Changeset.put_embed(:steps, updated_steps)
      |> Map.put(:changes, Map.put(changeset.changes, :steps, updated_steps))

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  def handle_event("delete_step", %{"index" => index_str}, socket) do
    changeset = socket.assigns.form.source
    index = String.to_integer(index_str)

    existing_steps = Ecto.Changeset.get_field(changeset, :steps, [])
    updated_steps = List.delete_at(existing_steps, index)

    new_changeset = Ecto.Changeset.put_embed(changeset, :steps, updated_steps)
    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  def handle_event("add_extract_field", %{"id" => id}, socket) do
    changeset = socket.assigns.form.source

    steps =
      Ecto.Changeset.get_field(changeset, :steps, [])
      |> Core.StructToMap.transform()

    # # this only works for nested steps
    # parent_step_index =
    #   Enum.find_index(steps, fn step ->
    #     Enum.any?(step.steps, &(&1.id == id))
    #   end)

    # parent_step = Enum.at(steps, parent_step_index)

    # nested_steps = parent_step.steps
    # nested_step_index = Enum.find_index(nested_steps, &(&1.id == id))

    # step = Enum.at(nested_steps, nested_step_index)

    step_index = Enum.find_index(steps, &(&1.id == id))

    step = Enum.at(steps, step_index)

    current_fields = (step.params || %{})["fields"] || %{}

    # Add a new empty field entry - use indexed structure
    new_idx = map_size(current_fields)

    updated_fields =
      Map.put(current_fields, "#{new_idx}", %{"key" => "", "value" => ""})

    updated_params = Map.put(step.params || %{}, "fields", updated_fields)
    updated_step = %{step | params: updated_params}

    # updated_steps = List.replace_at(nested_steps, nested_step_index, updated_step)

    # updated_parent_step = %{parent_step | steps: updated_steps}

    updated_steps = List.replace_at(steps, step_index, updated_step)

    new_changeset =
      changeset
      |> Ecto.Changeset.put_embed(:steps, updated_steps)

    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  def handle_event("remove_extract_field", %{"path" => path, "key" => key}, socket) do
    changeset = socket.assigns.form.source
    index = String.to_integer(path)

    steps = Ecto.Changeset.get_field(changeset, :steps, [])
    step = Enum.at(steps, index)

    current_fields = (step.params || %{})[:fields] || %{}
    updated_fields = Map.delete(current_fields, key) |> Map.delete(String.to_atom(key))

    updated_params = Map.put(step.params || %{}, :fields, updated_fields)
    updated_step = %{step | params: updated_params}
    updated_steps = List.replace_at(steps, index, updated_step)

    new_changeset = Ecto.Changeset.put_embed(:steps, changeset, updated_steps)
    {:noreply, assign(socket, form: to_form(new_changeset))}
  end

  defp decode_params_for_form(%Recipe{steps: steps} = recipe) do
    transformed_steps =
      steps
      |> Enum.map(fn step ->
        decode_transform_step_params(step)
      end)

    %{recipe | steps: transformed_steps}
  end

  defp decode_params_for_form(params), do: params

  defp decode_transform_step_params(
         %Step{action: "extract", params: %{"fields" => fields}} = step
       )
       when is_map(fields) do
    # Convert from %{"kagi" => "$.title", ...}
    # to %{"0" => %{"key" => "kagi", "value" => "$.title"}, "1" => {...}}
    transformed_fields =
      fields
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{key, value}, idx}, acc ->
        Map.put(acc, Integer.to_string(idx), %{"key" => key, "value" => value})
      end)

    %{step | params: Map.put(step.params || %{}, :fields, transformed_fields)}
  end

  defp decode_transform_step_params(params) do
    params
  end

  # Transform the indexed extract fields format into a proper map
  defp encode_params_for_save(%{"steps" => steps} = params) when is_map(steps) do
    transformed_steps =
      steps
      |> Enum.map(fn {idx, step} ->
        {idx, encode_transform_step_params(step)}
      end)
      |> Map.new()

    %{params | "steps" => transformed_steps}
  end

  defp encode_params_for_save(params), do: params

  defp encode_transform_step_params(
         %{"action" => "extract", "params" => %{"fields" => fields}} = step
       )
       when is_map(fields) do
    # Convert from %{"0" => %{"key" => "kagi", "value" => "$.title"}, "1" => {...}}
    # to %{"kagi" => "$.title", ...}
    transformed_fields =
      fields
      |> Enum.reduce(%{}, fn {_idx, %{"key" => key, "value" => value}}, acc ->
        Map.put(acc, key, value)
      end)

    put_in(step, ["params", "fields"], transformed_fields)
  end

  defp encode_transform_step_params(step), do: step

  ##########################

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
