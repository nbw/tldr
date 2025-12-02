defmodule Tldr.Parsers do
  @moduledoc false

  import Tldr.Kitchen.Recipe, only: [valid_type?: 1]

  def get_parser(type) when valid_type?(type) do
    type_str = to_string(type)
    String.to_existing_atom("Elixir.Tldr.Parsers.#{Macro.camelize(type_str)}")
  end
end
