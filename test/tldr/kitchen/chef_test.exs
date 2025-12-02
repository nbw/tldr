defmodule Tldr.Kitchen.ChefTest do
  use Tldr.DataCase

  alias Tldr.Kitchen.Actions
  alias Tldr.Kitchen.Recipe
  alias Tldr.Kitchen.Step
  alias Tldr.Kitchen.Chef

  test "execute/2" do
    recipe = %Recipe{
      steps: [
        %Step{
          action: %Actions.JsonGet{
            url: "https://hacker-news.firebaseio.com/v0/topstories.json"
          }
        },
        %Step{action: %Tldr.Kitchen.Actions.Limit{count: 3}},
        %Step{
          action: %Tldr.Kitchen.Actions.Map{},
          steps: [
            %Step{
              action: %Actions.JsonGet{
                url: "https://hacker-news.firebaseio.com/v0/item/{{val}}.json"
              }
            },
            %Step{
              action: %Tldr.Kitchen.Actions.Extract{
                fields: %{
                  title: "$.title",
                  url: "$.url"
                }
              }
            }
          ]
        }
      ]
    }

    Chef.cook(recipe)
    |> IO.inspect(label: "Cook")
  end
end
