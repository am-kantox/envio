defmodule Envio.Channels do
  @moduledoc """
  Channels storage.

  It manages all the channels currently existing in the system.
  """

  use GenServer

  require Logger

  alias Envio.{Channel, State}

  @doc """
  Starts a new channels bucket.
  """
  def start_link(_opts \\ []),
    do: GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)

  @doc """
  Default initialization callback (noop.)
  """
  def init(%State{} = state), do: {:ok, state}

  @doc """
  Get list of active subscriptions.
  """
  @spec state() :: %State{}
  def state(), do: GenServer.call(__MODULE__, :state)

  @doc """
  Registers new channel.
  """
  @spec register(atom() | {atom(), atom()}, list({atom(), %Channel{}})) :: :ok | {:error, {:already_registered, %Channel{}}}
  def register(host, channels),
    do: GenServer.call(__MODULE__, {:register, {host, channels}})

  ##############################################################################

  @doc false
  def handle_call(:state, _from, %State{} = state), do: {:reply, state, state}

  @doc false
  def handle_call({:register, {host, channels}}, _from, %State{} = state) do
    old_channels = Map.get(state.subscriptions, host, MapSet.new())
    obsoletes = MapSet.intersection(old_channels, MapSet.new(channels))
    Enum.each(obsoletes, fn {kind, channel} ->
      Registry.unregister_match(Envio.Registry, Envio.Channel.fq_name(channel), {kind, host})
    end)
    old_channels = MapSet.difference(old_channels, obsoletes)
    channels =
      Enum.reduce(channels, old_channels, fn {kind, channel}, acc ->
        with {:ok, _} <- Registry.register(Envio.Registry, Envio.Channel.fq_name(channel), {kind, host}) do
          MapSet.put(acc, {kind, channel})
        else
          error ->
            Logger.warn("Failed to register #{inspect({kind, channel})}. Error: #{inspect(error)}.")
            acc
        end
      end)

    {:reply, :ok, %State{state | subscriptions: Map.put(state.subscriptions, host, channels)}}
  end
end
