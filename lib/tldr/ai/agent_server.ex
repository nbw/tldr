defmodule Tldr.AI.AgentServer do
  use GenServer

  require Logger

  alias Tldr.AI.Chat

  # TODO: THIS AI SERVER is very RECIPE specific. It should be refactored to be more general.

  defstruct agent: nil, messages: [], result: nil, recipe_id: nil

  def start_link(opts) do
      recipe_id = Keyword.fetch!(opts, :recipe_id)
      GenServer.start_link(__MODULE__, opts, name: via_tuple(recipe_id))
    end

    def via_tuple(id) do
      {:via, Registry, {Tldr.AgentRegistry, id}}
    end

    # Get or start an agent for a user
    def get_or_start(current_scope, id) do
      case Registry.lookup(Tldr.AgentRegistry, id) do
        [{pid, _}] -> {:ok, pid}
        [] ->
          DynamicSupervisor.start_child(
            Tldr.AgentSupervisor,
            {__MODULE__, [current_scope: current_scope, recipe_id: id]}
          )
      end
    end

    def reset(current_scope, id) do
      stop_agent(id)
      get_or_start(current_scope, id)
    end

    def stop_agent(id) do
      case Registry.lookup(Tldr.AgentRegistry, id) do
        [{pid, _}] -> GenServer.stop(pid, :normal)
        [] -> :ok
      end
    end

    @impl true
    def init(opts) do
      current_scope = Keyword.fetch!(opts, :current_scope)
      recipe_id = Keyword.fetch!(opts, :recipe_id)

      Logger.debug("Initializing agent server for recipe #{recipe_id}")

      agent = Chat.new(current_scope, recipe_id, self())

      {:ok, %__MODULE__{agent: agent, messages: [], result: nil, recipe_id: recipe_id}}
    end

    def send_message(recipe_id, message, callback \\ nil) do
      GenServer.cast(via_tuple(recipe_id), {:send_message, message, callback})
    end

    def list_messages(agent_id) do
      GenServer.call(via_tuple(agent_id), :list_messages)
    end

    @impl true
    def handle_info({:save_steps, result, channel}, state) do
      Logger.warning("RECIPE RELOADED EVENT")
      TldrWeb.PubSub.broadcast(channel, {:save_steps, result})
      {:noreply, %{state | result: result}}
    end

    def handle_info({:uuid, uuids}, state) do
      Logger.warning("UUIDs generated: #{inspect(uuids)}")
      {:noreply, state}
    end

    @impl true
    def handle_call(:list_messages, _, %__MODULE__{messages: messages} = state) do
      {:reply, messages, state}
    end

    @impl true
    def handle_call({:send_message, message}, _, state) do
      Logger.info("Sending message: #{message}")
      # TODO: create a function that returns a user message
      user_message = %{role: :user, content: message}
      # TODO: pass the user message to the chat
      case Chat.send_message(state.agent, message) do
        {:ok, result} ->
          response = Chat.get_last_response(result)
          assistant_message = %{role: :assistant, content: response}
          {:reply, {:ok, assistant_message}, %{state | messages: state.messages ++ [user_message, assistant_message]}}
        {:error, reason} ->
          Logger.error("Error sending message: #{reason}")
          {:reply, {:error, reason}, state}
      end
    end

    @impl true
    def handle_cast({:send_message, message, callback}, state) do
      Logger.info("Sending message: #{message}")
      # TODO: create a function that returns a user message
      user_message = %{role: :user, content: message}
      # TODO: pass the user message to the chat
      case Chat.send_message(state.agent, message) do
        {:ok, result} ->
          response = Chat.get_last_response(result)
          assistant_message = %{role: :assistant, content: response}

          if callback do
            callback.({:ok, assistant_message})
          end

          {:noreply, %{state | messages: state.messages ++ [user_message, assistant_message]}}
        {:error, reason} ->
          Logger.error("Error sending message: #{reason}")
          {:noreply, state}
      end
    end
end
