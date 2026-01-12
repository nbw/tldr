defmodule Tldr.Kitchen.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(web json rss)a

  schema "recipes" do
    field :name, :string
    field :url, :string
    field :type, Ecto.Enum, values: @types
    field :user_id, :id

    embeds_many :steps, Tldr.Kitchen.Step, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recipe, attrs, user_scope) do
    recipe
    |> cast(attrs, [:name, :type, :url])
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

  defguard json?(val) when val == :json or val == "json"
  defguard rss?(val) when val == :rss or val == "rss"
  defguard web?(val) when val == :web or val == "web"
end
