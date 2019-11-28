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
    checker =
      quote(
        location: :keep,
        generated: true,
        do: @after_compile({Envio.Utils, :subscriber_finalizer})
      )

    ast =
      case Keyword.get(opts, :as, :gen_server) do
        :barebone ->
          []

        [{:phoenix_pubsub, options}] ->
          adapter = Keyword.get(options, :adapter, Phoenix.PubSub.PG2)
          channels = Keyword.get(options, :channels, [])
          messages = Keyword.get(options, :messages, [:envio])

          quote generated: true, location: :keep do
            use GenServer

            @adapter unquote(adapter)
            @pubsub_module Module.concat([__MODULE__, "PubSub"])
            @messages unquote(messages)
            @channels Enum.map(
                        unquote(channels),
                        &%Envio.Channel{source: @pubsub_module, name: &1}
                      )

            def start_link(opts \\ []) do
              {name, opts} = Keyword.pop(opts, :name, __MODULE__)
              GenServer.start_link(__MODULE__, %Envio.State{options: opts}, name: name)
            end

            @spec state :: Envio.State.t()
            def state, do: GenServer.call(__MODULE__, :state)

            @impl GenServer
            def init(%Envio.State{} = state),
              do: {:ok, state, {:continue, :connect}}

            @impl GenServer
            def handle_call(:state, _from, %Envio.State{} = state),
              do: {:reply, state, state}

            @impl GenServer
            def handle_continue(:connect, %Envio.State{} = state) do
              case @adapter.start_link(name: @pubsub_module) do
                {:ok, pid} ->
                  subscriptions =
                    for %Envio.Channel{source: source, name: channel} = envio_channel <- @channels do
                      %{envio_channel => Phoenix.PubSub.subscribe(source, channel)}
                    end

                  {:noreply, %Envio.State{state | subscriptions: subscriptions, pid: pid}}

                other ->
                  {:noreply, state}
              end
            end

            Enum.each(@messages, fn msg ->
              @msg msg

              @impl GenServer
              def handle_info({@msg, message}, state),
                do: handle_envio(message, state)
            end)

            @impl GenServer
            def handle_info({:DOWN, _, :process, _pid, reason}, _),
              do: {:stop, {:disconnected, reason}, nil}
          end

        [{:child_spec, overrides}] ->
          type = Keyword.get(overrides, :type, :worker)
          restart = Keyword.get(overrides, :restart, :permanent)
          shutdown = Keyword.get(overrides, :shutdown, 500)

          quote generated: true, location: :keep do
            def child_spec(opts) do
              %{
                id: __MODULE__,
                start: {__MODULE__, :start_link, [opts]},
                type: unquote(type),
                restart: unquote(restart),
                shutdown: unquote(shutdown)
              }
            end
          end

        other ->
          module =
            Module.concat([
              other
              |> to_string()
              |> Macro.camelize()
            ])

          unless Code.ensure_loaded?(module),
            do:
              raise(Envio.InconsistentUsing,
                who: module,
                reason: "Cannot load the module specified (#{module})"
              )

          quote location: :keep do
            use unquote(module)

            @doc """
            Helper generated by the `Envio.Subscriber` scaffold. This `pub_sub`
            `GenServer` might be started by invoking `#{__MODULE__}.start_link`.
            """
            @spec start_link(opts :: keyword()) :: GenServer.on_start()
            def start_link(opts \\ []),
              do: GenServer.start_link(__MODULE__, %Envio.State{options: opts}, name: __MODULE__)

            @channels unquote(opts)
                      |> Keyword.get(:channels, [])
                      |> Enum.map(fn {source, channel} ->
                        %Envio.Channel{source: source, name: channel}
                      end)

            @impl GenServer
            @doc false
            def init(%Envio.State{} = state), do: do_subscribe(@channels, state)
          end
      end

    quote generated: true, location: :keep do
      @behaviour Envio.Subscriber

      unquote(ast)
      unquote(checker)

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

      @spec subscribe(channel :: %Envio.Channel{} | [%Envio.Channel{}]) :: {:ok, %Envio.State{}}
      @doc """
      Subscribes to the channel(s) given in a runtime.
      """
      def subscribe(%Envio.Channel{} = channel), do: subscribe([channel])

      def subscribe([_ | _] = channels),
        do: GenServer.call(__MODULE__, {:subscribe, channels})

      defoverridable handle_envio: 2

      ##########################################################################

      @impl GenServer
      @doc false
      @spec handle_call(
              {:subscribe, channels :: [%Envio.Channel{}]},
              GenServer.from(),
              state :: Envio.State.t()
            ) :: {:reply, %MapSet{}, Envio.State.t()}
      def handle_call({:subscribe, [_ | _] = channels}, _from, %Envio.State{} = state) do
        case do_subscribe(channels, state) do
          {:ok, %Envio.State{subscriptions: subscriptions}} ->
            {:reply, subscriptions[__MODULE__], state}

          error ->
            {:reply, {:error, error}, state}
        end
      end

      @impl GenServer
      @doc false
      def handle_info({:envio, {channel, message}}, state),
        do: handle_envio(message, state)

      def handle_info({:envio, message}, state),
        do: handle_envio(message, state)

      ##########################################################################

      @spec do_subscribe(channels :: [%Envio.Channel{}], state :: %Envio.State{}) ::
              {:ok, %Envio.State{}}
      defp do_subscribe(channels, %Envio.State{} = state) do
        channels =
          channels
          |> MapSet.new()
          |> Enum.map(&{:pub_sub, &1})

        Enum.each(channels, fn
          {:pub_sub, channel} ->
            Registry.register(
              Envio.Registry,
              Envio.Channel.fq_name(channel),
              {:pub_sub, __MODULE__}
            )

          # Maybe support :dispatch here as well?
          {kind, channel} ->
            raise(Envio.InconsistentUsing,
              who: "#{__MODULE__}.subscribe/1",
              reason: "Wrong type #{kind} for channel #{inspect(channel)}. Must be :pub_sub."
            )
        end)

        channels = Envio.Channels.register(__MODULE__, channels)
        {:ok, %Envio.State{state | subscriptions: %{__MODULE__ => channels}}}
      end
    end
  end
end
