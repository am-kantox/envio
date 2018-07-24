defmodule Envio.Subscriber do
  @moduledoc """
  Subscriber interface.

  It manages all the channels currently existing in the system.
  """

  @doc """
  The callback to subscribe stuff to `Envio`.
  """
  @callback handle_envio(binary() | atom(), map()) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: term()

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      require Logger
      use GenServer

      @behaviour Envio.Subscriber

      @namespace Macro.underscore(__MODULE__)
      @fq_joiner "."
      @max_messages 10

      @impl true
      def handle_envio(message, state) do
        messages =
          case Enum.count(state.messages) do
            n when n > 10 ->
              with [_ | tail] <- :lists.reverse(state.messages),
                   do: :lists.reverse([message | tail])

            _ ->
              [message | state.messages]
          end

        {:noreply, %Envio.State{state | messages: messages}}
      end

      defoverridable handle_envio: 2

      ##########################################################################

      def start_link(_opts \\ []),
        do: GenServer.start_link(__MODULE__, %Envio.State{}, name: __MODULE__)

      @channels opts
                |> Keyword.get(:channels, [])
                |> Enum.map(fn
                  {source, channel} -> {:pub_sub, %Envio.Channel{source: source, name: channel}}
                end)
                |> MapSet.new()

      @impl true
      def init(%Envio.State{} = state) do
        Enum.each(@channels, fn
          {:pub_sub, channel} ->
            Registry.register(
              Envio.Registry,
              Envio.Channel.fq_name(channel),
              {:pub_sub, __MODULE__}
            )

          {kind, channel} ->
            Logger.warn("Wrong type #{kind} for channel #{inspect(channel)}. Must be :pub_sub.")
        end)

        Envio.Channels.register(__MODULE__, @channels)
        {:ok, %Envio.State{state | subscriptions: %{__MODULE__ => @channels}}}
      end

      @impl true
      def handle_info({:envio, {channel, message}}, state),
        do: handle_envio(message, state)

      ##########################################################################
    end
  end
end
