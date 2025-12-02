defmodule Tldr.Kitchen.Step do
  use Tldr.Core.EmbeddedEctoSchema

  embedded_schema do
    field :action, :string
    field :title, :string
    field :description, :string
    field :params, :map
    field :actor, :any, virtual: true

    embeds_many :steps, Tldr.Kitchen.Step
  end

  @type t :: %__MODULE__{
          action: String.t(),
          title: String.t(),
          description: String.t(),
          params: map() | struct(),
          steps: list(__MODULE__.t())
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
        params = Map.get(attrs, :params, %{})
        module = Module.concat([Tldr.Kitchen.Actions, Macro.camelize(action)])

        case module.apply(params) do
          {:ok, struct} ->
            put_change(changeset, :actor, struct)

          _ ->
            changeset
        end
    end
  end
end
