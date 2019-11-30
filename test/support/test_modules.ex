# PUBLISHERS

defmodule Spitter.Registry do
  use Envio.Publisher, manager: :registry, channel: :main
  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end

defmodule Spitter.PG2 do
  use Envio.Publisher, manager: :phoenix_pub_sub, channel: :main
  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end

# SUBSCRIBERS

defmodule Sucker do
  def suck(what), do: IO.inspect(what, label: "Sucked")
end

defmodule PubSucker do
  use Envio.Subscriber, manager: :registry, channels: [{Spitter.Registry, :foo}]

  @impl Envio.Subscriber
  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end

# defmodule ExistingGenServer do
#   use Envio.Subscriber, manager: :barebone

#   use GenServer

#   @spec start_link(keyword()) :: GenServer.on_start()
#   @doc false
#   def start_link(opts \\ []),
#     do: GenServer.start_link(__MODULE__, %Envio.State{options: opts}, name: __MODULE__)

#   @impl GenServer
#   @doc false
#   def init(%Envio.State{} = state),
#     do: {:ok, state, {:continue, :connect}}

#   @impl GenServer
#   @doc false
#   def handle_continue(:connect, %Envio.State{} = state) do
#     {:ok, %Envio.State{} = state} =
#       do_subscribe([%Envio.Channel{source: Spitter.Registry, name: :foo}], state)

#     {:noreply, state}
#   end

#   @impl Envio.Subscriber
#   @doc false
#   def handle_envio(message, state) do
#     {:noreply, state} = super(message, state)
#     IO.inspect({message, state}, label: "PubSucked")
#     {:noreply, state}
#   end
# end

defmodule Envio.IOBackend do
  @moduledoc false

  @behaviour Envio.Backend

  @impl Envio.Backend
  def on_envio(message, _meta) do
    IO.inspect({message, message[:pid]}, label: "[★Envío★]")

    case Process.send(message[:pid], :on_envio_called, []) do
      :ok -> {:ok, message[:pid]}
      error -> {:error, error}
    end
  end
end

defmodule Envio.Phoenix do
  @moduledoc false

  use Envio.Subscriber, manager: :phoenix_pub_sub, channels: ["foo"]

  @impl Envio.Subscriber
  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end
