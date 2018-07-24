defmodule Envio.Channels do
  @moduledoc """
  Channels storage.

  It manages all the channels currently existing in the system.
  """

  use GenServer

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
  Get list of active channels.
  """
  @spec all() :: list(%Channel{})
  def all(), do: GenServer.call(__MODULE__, :all)

  @doc """
  Registers new channel.

  ## Examples

      iex> Envio.Channels.register(%Envio.Channel{source: Foo, name: :bar})
      :ok
      iex> Envio.Channels.all()
      [%Envio.Channel{source: Foo, name: :bar}]
      iex> Envio.Channels.register(%Envio.Channel{source: Foo, name: :bar})
      {:error, {:already_registered, %Envio.Channel{name: :bar, source: Foo}}}
  """
  @spec register(%Channel{}) :: :ok | {:error, {:already_registered, %Channel{}}}
  def register(%Channel{} = channel),
    do: GenServer.call(__MODULE__, {:register, channel})

  ##############################################################################

  @doc false
  def handle_call(:all, _from, state),
    do: {:reply, state.channels, %State{} = state}

  @doc false
  def handle_call({:register, channel}, _from, %State{} = state) do
    existing =
      Enum.find(
        state.channels,
        &(&1.name == channel.name && &1.source == channel.source)
      )

    do_register(channel, state, existing)
  end

  defp do_register(channel, state, nil) do
    {:reply, :ok, %State{state | channels: [channel | state.channels]}}
  end

  defp do_register(_, state, existing),
    do: {:reply, {:error, {:already_registered, existing}}, state}
end
