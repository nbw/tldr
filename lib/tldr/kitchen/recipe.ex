defmodule Tldr.Kitchen.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(rss xml json)a

  schema "recipes" do
    field :name, :string
    field :type, Ecto.Enum, values: @types
    field :url, :string
    field :user_id, :id

    embeds_many :steps, Tldr.Kitchen.Step

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recipe, attrs, user_scope) do
    recipe
    |> cast(attrs, [:name, :type, :url])
    |> validate_required([:name, :type, :url])
    |> put_change(:user_id, user_scope.user.id)
    |> cast_embed(:steps)
  end

  def types, do: @types

  defguard valid_type?(type) when type in @types
end
