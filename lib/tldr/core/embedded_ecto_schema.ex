defmodule Tldr.Core.EmbeddedEctoSchema do
  @moduledoc """
  Provides a set of helper functions for converting a map to an embedded schema.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      require Logger

      def changeset(module, params) do
        module
        |> cast(params, __cast_fields__(module.__struct__))
        |> cast_embeds(module)
      end

      def cast_embeds(chg, module) do
        Enum.reduce(__embeds__(module.__struct__), chg, fn embed, chg ->
          cast_embed(chg, embed, with: &changeset/2)
        end)
      end

      def __cast_fields__(struct) do
        __fields__(struct) -- __embeds__(struct)
      end

      def __fields__(struct) do
        struct.__schema__(:fields)
      end

      def __embeds__(struct) do
        struct.__schema__(:embeds)
      end

      defoverridable changeset: 2

      @before_compile Tldr.Core.EmbeddedEctoSchema
    end
  end

  # this code is add at the end of the module rather than the top
  defmacro __before_compile__(_env) do
    quote do
      # apply self to self
      def apply(%__MODULE__{} = struct) do
        struct
        |> changeset(Tldr.Core.StructToMap.transform(struct))
        |> apply_action(:insert)
      end

      # apply params
      def apply(params) do
        %__MODULE__{}
        |> changeset(params)
        |> apply_action(:insert)
      end

      def apply!(params) do
        with {:ok, struct} <- apply(params) do
          struct
        end
      end

      def map_apply(enum) do
        Enum.reduce(enum, [], fn d, acc ->
          case apply(d) do
            {:ok, value} -> [value | acc]
            {:error, error} ->
              Logger.error("Error applying #{inspect(d)}")
              Logger.error("#{inspect(error)}")
              acc
          end
        end)
      end
    end
  end
end
