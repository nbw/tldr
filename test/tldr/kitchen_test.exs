defmodule Tldr.KitchenTest do
  use Tldr.DataCase

  alias Tldr.Kitchen

  describe "recipes" do
    alias Tldr.Kitchen.Recipe

    import Tldr.AccountsFixtures, only: [user_scope_fixture: 0]
    import Tldr.KitchenFixtures

    @invalid_attrs %{name: nil, type: nil, url: nil}

    test "list_recipes/1 returns all scoped recipes" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      recipe = recipe_fixture(scope)
      other_recipe = recipe_fixture(other_scope)
      assert Kitchen.list_recipes(scope) == [recipe]
      assert Kitchen.list_recipes(other_scope) == [other_recipe]
    end

    test "get_recipe!/2 returns the recipe with given id" do
      scope = user_scope_fixture()

      recipe =
        recipe_fixture(scope, %{
          steps: [
            %{
              action: "limit",
              title: "Grab 50 items",
              description: "Grab 50 items",
              params: %{
                "count" => 50
              }
            }
          ]
        })

      recipe = %{
        recipe
        | steps:
            Enum.map(
              recipe.steps,
              &%{&1 | actor: nil}
            )
      }

      other_scope = user_scope_fixture()
      assert Kitchen.get_recipe!(scope, recipe.id) == recipe
      assert_raise Ecto.NoResultsError, fn -> Kitchen.get_recipe!(other_scope, recipe.id) end
    end

    test "create_recipe/2 with valid data creates a recipe" do
      valid_attrs = %{name: "some name", type: "json", url: "some url"}
      scope = user_scope_fixture()

      assert {:ok, %Recipe{} = recipe} = Kitchen.create_recipe(scope, valid_attrs)
      assert recipe.name == "some name"
      assert recipe.type == :json
      assert recipe.url == "some url"
      assert recipe.user_id == scope.user.id
    end

    test "create_recipe/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Kitchen.create_recipe(scope, @invalid_attrs)
    end

    test "update_recipe/3 with valid data updates the recipe" do
      scope = user_scope_fixture()
      recipe = recipe_fixture(scope)
      update_attrs = %{name: "some updated name", type: "xml", url: "some updated url"}

      assert {:ok, %Recipe{} = recipe} = Kitchen.update_recipe(scope, recipe, update_attrs)
      assert recipe.name == "some updated name"
      assert recipe.type == :xml
      assert recipe.url == "some updated url"
    end

    test "update_recipe/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      recipe = recipe_fixture(scope)

      assert_raise MatchError, fn ->
        Kitchen.update_recipe(other_scope, recipe, %{})
      end
    end

    test "update_recipe/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      recipe = recipe_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Kitchen.update_recipe(scope, recipe, @invalid_attrs)
      assert recipe == Kitchen.get_recipe!(scope, recipe.id)
    end

    test "delete_recipe/2 deletes the recipe" do
      scope = user_scope_fixture()
      recipe = recipe_fixture(scope)
      assert {:ok, %Recipe{}} = Kitchen.delete_recipe(scope, recipe)
      assert_raise Ecto.NoResultsError, fn -> Kitchen.get_recipe!(scope, recipe.id) end
    end

    test "delete_recipe/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      recipe = recipe_fixture(scope)
      assert_raise MatchError, fn -> Kitchen.delete_recipe(other_scope, recipe) end
    end

    test "change_recipe/2 returns a recipe changeset" do
      scope = user_scope_fixture()
      recipe = recipe_fixture(scope)
      assert %Ecto.Changeset{} = Kitchen.change_recipe(scope, recipe)
    end
  end
end
