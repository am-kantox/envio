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
  @spec register(atom() | {atom(), atom()}, list({atom(), %Channel{}})) ::
          :ok | {:error, {:already_registered, %Channel{}}}
  def register(host, channels),
    do: GenServer.call(__MODULE__, {:register, {host, channels}})

  ##############################################################################

  @doc false
  def handle_call(:state, _from, %State{} = state), do: {:reply, state, state}

  @doc false
  def handle_call({:register, {host, channels}}, _from, %State{} = state) do
    channels = MapSet.new(channels)

    old_channels =
      state.subscriptions
      |> Map.get(host, MapSet.new())
      |> do_unregister({host, channels})
      |> MapSet.difference(channels)

    channels = Enum.reduce(channels, old_channels, &do_register(host, &1, &2))

    {:reply, channels,
     %State{state | subscriptions: Map.put(state.subscriptions, host, channels)}}
  end

  ##############################################################################

  defp do_unregister(old_channels, {host, neu_channels}) do
    old_channels
    |> MapSet.intersection(neu_channels)
    |> Enum.each(fn {kind, channel} ->
      Registry.unregister_match(Envio.Registry, Envio.Channel.fq_name(channel), {kind, host})
    end)

    old_channels
  end

  defp do_register(host, {:dispatch, channel}, acc) do
    with {:ok, _} <-
           Registry.register(Envio.Registry, Envio.Channel.fq_name(channel), {:dispatch, host}) do
      MapSet.put(acc, {:dispatch, channel})
    else
      error ->
        Logger.warn(
          "Failed to register dispatcher #{inspect(channel)}. Error: #{inspect(error)}."
        )

        acc
    end
  end

  defp do_register(_host, {:pub_sub, channel}, acc),
    do: MapSet.put(acc, {:pub_sub, channel})
end
