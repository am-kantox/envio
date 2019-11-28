defmodule Spitter do
  use Envio.Publisher, channel: :main
  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end

defmodule Sucker do
  def suck(what), do: IO.inspect(what, label: "Sucked")
end

defmodule PubSucker do
  use Envio.Subscriber, channels: [{Spitter, :foo}]

  @impl Envio.Subscriber
  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end

defmodule ExistingGenServer do
  use Envio.Subscriber, as: :barebone

  use GenServer

  @spec start_link(list()) ::
          {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}
  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, %Envio.State{options: opts}, name: __MODULE__)

  @impl GenServer
  @doc false
  def init(%Envio.State{} = state),
    do: do_subscribe([%Envio.Channel{source: Spitter, name: :foo}], state)

  @impl Envio.Subscriber
  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end

defmodule Envio.IOBackend do
  @moduledoc false

  @behaviour Envio.Backend

  @impl Envio.Backend
  def on_envio(message, _meta) do
    IO.inspect({message, message[:pid]}, label: "[★Envío★]")
    Process.send(message[:pid], :on_envio_called, [])
  end
end

defmodule Envio.Phoenix do
  use Envio.Subscriber, as: [phoenix_pubsub: [channels: ["foo"]]]

  @impl Envio.Subscriber
  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end
