defmodule Tldr.AI.AgentServer do
  use GenServer

  def start_link(opts) do
      agent_id = Keyword.fetch!(opts, :agent_id)
      GenServer.start_link(__MODULE__, opts, name: via_tuple(agent_id))
    end

    defp via_tuple(agent_id) do
      {:via, Registry, {Tldr.AgentRegistry, agent_id}}
    end

    # Get or start an agent for a user
    def get_or_start(agent_id) do
      case Registry.lookup(Tldr.AgentRegistry, agent_id) do
        [{pid, _}] -> {:ok, pid}
        [] ->
          DynamicSupervisor.start_child(
            Tldr.AgentSupervisor,
            {__MODULE__, agent_id: agent_id}
          )
      end
    end
end
