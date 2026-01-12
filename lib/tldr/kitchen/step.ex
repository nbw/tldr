defmodule Tldr.Kitchen.Step do
  use Tldr.Core.EmbeddedEctoSchema

  @derive {JSON.Encoder,
           only: [
             :id,
             :action,
             :title,
             :locked,
             :index,
             :params
           ]}
  embedded_schema do
    field :action, :string
    field :title, :string
    field :locked, :boolean, default: false
    field :index, :integer, default: 0
    field :params, :map, default: %{}

    field :actor, :any, virtual: true
    field :hydrate, :boolean, default: false, virtual: true
  end

  @type t :: %__MODULE__{
          action: String.t(),
          title: String.t(),
          actor: any(),
          params: map() | struct(),
          locked: boolean()
        }

  def changeset(module, attrs) do
    module
    |> cast(attrs, __cast_fields__(module.__struct__))
    |> cast_embeds(module)
    |> cast_actor(attrs)
  end

  def cast_actor(changeset, attrs) do
    case get_field(changeset, :action) do
      nil ->
        changeset

      action ->
        params = get_params(attrs)
        module = Module.concat([Tldr.Kitchen.Actions, Macro.camelize(action)])

        case module.apply(params) do
          {:ok, struct} ->
            put_change(changeset, :actor, struct)

          _ ->
            changeset
        end
    end
  end

  def new(params \\ %{}) do
    %__MODULE__{id: Ecto.UUID.generate()}
    |> changeset(params)
    |> Ecto.Changeset.apply_changes()
  end

  @doc """
  Recursively hydrates a step and its nested steps.
  """
  def hydrate(steps) when is_list(steps) do
    Enum.map(steps, &hydrate/1)
  end

  def hydrate(%__MODULE__{hydrate: false} = step) do
    with {:ok, step} <- apply(step) do
      %{step | hydrate: true}
    end
  end

  def hydrate(%__MODULE__{} = step), do: step

  defp get_params(%{"params" => params}), do: params
  defp get_params(%{params: params}), do: params
  defp get_params(params), do: params
end
