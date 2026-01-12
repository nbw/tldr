defmodule TldrWeb.RecipeLive.Components.StepComponent do
  defmacro __using__(_opts) do
    quote do
      require Logger

      def handle_event(_event_name, _param, socket) do
        Logger.warning("Step component #{__MODULE__} does not implement handle_event")
        {:noreply, socket}
      end

      defoverridable handle_event: 3
    end
  end
end
