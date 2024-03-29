# PUBLISHERS

defmodule Spitter.Registry do
  use Envio.Publisher, manager: :registry, channel: :main
  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end

defmodule Spitter.PG2 do
  use Envio.Publisher, manager: :phoenix_pub_sub, adapter: :pg2, channel: "main"
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

defmodule PG2Sucker do
  @moduledoc false

  use Envio.Subscriber, manager: :phoenix_pub_sub, channels: ["main"]

  @impl Envio.Subscriber
  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PG2Sucked")
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

defmodule Envio.Slack do
  @moduledoc false

  @behaviour Envio.Backend

  @impl Envio.Backend
  def on_envio(message, _meta), do: {:ok, message}
end

defmodule Envio.IOBackend.Registry do
  @moduledoc false

  @behaviour Envio.Backend

  @impl Envio.Backend
  def on_envio(%{pid: pid} = message, _meta) do
    IO.inspect({message, pid}, label: "[★Envío Reg★]")

    case Process.send(pid, :on_envio_called, []) do
      :ok -> {:ok, pid}
      error -> {:error, error}
    end
  end

  def on_envio(_message, _meta), do: {:error, :no_callback}
end

defmodule Envio.IOBackend.PG2 do
  @moduledoc false

  @behaviour Envio.Backend

  @impl Envio.Backend
  def on_envio(message, _meta) do
    IO.inspect({message, message[:pid]}, label: "[★Envío PG2★]")

    case Process.send(message[:pid], :on_envio_called, []) do
      :ok -> {:ok, message[:pid]}
      error -> {:error, error}
    end
  end
end

defmodule Envio.ProcessBackendHandler do
  @moduledoc false

  use GenServer

  def start_link, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl GenServer
  def init(%{} = init_arg), do: {:ok, init_arg}

  @impl GenServer
  def handle_info(%{callback: pid} = message, state) do
    IO.inspect(message, label: "[★Envío Process★]")
    Process.send(pid, :on_envio_called, [])
    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}
end
