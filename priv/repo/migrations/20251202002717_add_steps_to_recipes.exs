defmodule Tldr.Repo.Migrations.AddStepsToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :steps, {:array, :map}
    end
  end
end
