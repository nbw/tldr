defmodule Tldr.Feed do
  @moduledoc false

  alias Tldr.Parsers
  alias Tldr.Kitchen.Recipe

  def cook_recipe(%Recipe{} = recipe) do
    parser = Parsers.get_parser(recipe.type)

    with {:ok, %{body: body}} <- Req.get(recipe.url),
         {:ok, data} <- parser.parse(body) do
      Tldr.Feed.FeedProtocol.index(data)
    end
  end
end
