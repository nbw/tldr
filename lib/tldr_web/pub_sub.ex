defmodule TldrWeb.PubSub do
  alias Phoenix.PubSub

  def subscribe(topic) do
    PubSub.subscribe(Tldr.PubSub, topic)
  end

  def broadcast(topic, message) do
    PubSub.broadcast(Tldr.PubSub, topic, message)
  end
end
