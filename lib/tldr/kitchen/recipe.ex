defmodule Tldr.Kitchen.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(rss json)a

  schema "recipes" do
    field :name, :string
    field :type, Ecto.Enum, values: @types
    field :user_id, :id

    embeds_many :steps, Tldr.Kitchen.Step, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recipe, attrs, user_scope) do
    recipe
    |> cast(attrs, [:name, :type])
    |> validate_required([:name, :type])
    |> put_change(:user_id, user_scope.user.id)
    |> cast_embed(:steps)
  end

  def types, do: @types

  defguard valid_type?(type) when type in @types

  def default_steps(type) when is_binary(type) do
    type
    |> String.to_existing_atom()
    |> default_steps()
  end

  def default_steps(:rss) do
    [Tldr.Kitchen.Step.new(%{action: "json_get"})]
  end

  def default_steps(_), do: []
end
