defmodule Envio.Subscriber do
  @moduledoc """
  Subscriber helper scaffold.

  To easy register the `pub_sub` consumer in `Envio.Registry`, one might
  use this helper to scaffold the registering/unregistering code.
  It turns the module into the `GenServer` and provides the handy wrapper
  for the respective `handle_info/2`. One might override
  `handle_envio` to implement custom handling.

  The typical usage would be:

  ```elixir
  defmodule PubSubscriber do
    use Envio.Subscriber, channels: [{PubPublisher, :foo}]

    def handle_envio(message, state) do
      with {:noreply, state} <- super(message, state) do
        IO.inspect({message, state}, label: "Received message")
        {:noreply, state}
      end
    end
  end
  ```

  If channels are not specified as a parameter in call to `use Envio.Subscriber`,
  this module might subscribe to any publisher later with `subscribe/1`:

  ```elixir
  PubSubscriber.subscribe(%Envio.Channel{source: PubPublisher, name: :foo})
  ```

  For how to publish, see `Envio.Publisher`.
  """

  @doc """
  The callback to subscribe stuff to `Envio`.
  """
  @callback handle_envio(message :: :timeout | term(), state :: Envio.State.t()) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: Envio.State.t()

  defmacro __using__(opts \\ []) do
    {manager, opts} = Keyword.pop(opts, :manager, :registry)
    manager = Module.concat(["Envio", "Subscribers", Macro.camelize("#{manager}")])

    quote location: :keep, generated: true do
      require Logger

      use GenServer

      @behaviour Envio.Subscriber
      @after_compile {Envio.Utils, :subscriber_finalizer}

      use unquote(manager), unquote(opts)

      @doc """
      Helper generated by the `Envio.Subscriber` scaffold. This `pub_sub`
      `GenServer` might be started by invoking `#{__MODULE__}.start_link`.
      """
      @spec start_link(opts :: keyword()) :: GenServer.on_start()
      def start_link(opts \\ []),
        do: GenServer.start_link(__MODULE__, %Envio.State{options: opts}, name: __MODULE__)

      @impl GenServer
      @doc false
      def init(%Envio.State{} = state),
        do: {:ok, state, {:continue, :connect}}

      @impl GenServer
      @doc false
      def handle_continue(:connect, %Envio.State{} = state),
        do: {:noreply, do_subscribe(state)}

      @spec state :: Envio.State.t()
      @doc """
      Returns the state of this process, including all the subscriptions,
      last messages processed, the PID of the underlying `Phoenix.PubSub` etc.
      """
      def state, do: GenServer.call(__MODULE__, :state)

      @impl GenServer
      @doc false
      def handle_call(:state, _from, %Envio.State{} = state),
        do: {:reply, state, state}

      @namespace Macro.underscore(__MODULE__)
      @fq_joiner "."
      @max_messages Application.get_env(:envio, :subscriber_queue_size, 10)

      @impl Envio.Subscriber
      @doc """
      Default implementation of the callback invoked when the message is received.
      """
      def handle_envio(message, state) do
        messages =
          case Enum.count(state.messages) do
            n when n > @max_messages ->
              with [_ | tail] <- :lists.reverse(state.messages),
                   do: :lists.reverse([message | tail])

            _ ->
              [message | state.messages]
          end

        {:noreply, %Envio.State{state | messages: messages}}
      end

      defoverridable handle_envio: 2

      ##########################################################################

      @spec subscribe(channel :: Envio.Channel.t() | [Envio.Channel.t()]) ::
              {:ok, Envio.State.t()}
      @doc """
      Subscribes to the channel(s) given in a runtime.
      """
      def subscribe(%Envio.Channel{} = channel), do: subscribe([channel])

      def subscribe([_ | _] = channels),
        do: {:ok, GenServer.call(__MODULE__, {:subscribe, channels})}

      @impl GenServer
      @doc false
      def handle_call({:subscribe, [_ | _] = channels}, _from, %Envio.State{} = state),
        do: {:reply, :ok, do_subscribe(channels, state)}

      @impl GenServer
      @doc false
      def handle_info({:envio, {channel, message}}, state),
        do: handle_envio(message, state)
    end
  end
end
