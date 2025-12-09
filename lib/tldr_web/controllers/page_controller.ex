defmodule TldrWeb.PageController do
  use TldrWeb, :controller

  def home(conn, _params) do
    recipes =
      case conn.assigns[:current_scope] do
        scope when not is_nil(scope) ->
          Tldr.Kitchen.list_recipes(scope)
        _ ->
          nil
      end

    render(conn, :home, recipes: recipes)
  end
end
