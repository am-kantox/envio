defmodule Envio.Publisher do
  @moduledoc """
  Publisher helper scaffold.

  Simply `use Envio.Publisher` in the module that should publish messages.
  The `broadcast/2` function becomes available. If the optional `channel:`
  argument is passed to `use Envio.Publisher`, this channel is considered
  the default one and `broadcast/1` function appears to publish directly
  to the default channel.

  The ready-to-copy-paste example of usage would be:

  ```elixir
  defmodule MyPub do
    use Envio.Publisher, channel: :main

    def publish(channel, what), do: broadcast(channel, what)
    def publish(what), do: broadcast(what)
  end
  ```

  All the _subscribers_ of the particular channel the message was published
  to, will either receive a message (in the case of
  [`:pub_sub`](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub))
  or called back with the function provided on subscription
  ([`:dispatch`](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-dispatcher)).

  The publisher does not wrap [`:via`](https://hexdocs.pm/elixir/master/Registry.html#module-using-in-via)
  functionality since it makes not much sense.

  For how to subscribe, see `Envio.Subscriber`.
  """

  @doc """
  The callback to publish stuff to `Envio`.
  """
  @callback broadcast(channel :: binary() | atom(), message :: map()) :: :ok

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      require Logger

      @behaviour Envio.Publisher

      @registry_kind Keyword.get(opts, :type, :both)
      @channel opts[:channel]

      @impl Envio.Publisher
      def broadcast(channel, %{} = message) when is_binary(channel),
        do: do_broadcast(@registry_kind, channel, message)

      @impl Envio.Publisher
      def broadcast(channel, %{} = message) when is_atom(channel),
        do: channel |> Atom.to_string() |> broadcast(message)

      if is_binary(@channel) or is_atom(@channel) do
        @spec broadcast(message :: map()) :: :ok
        def broadcast(%{} = message), do: broadcast(@channel, message)
      end

      defoverridable broadcast: 2

      ##########################################################################

      @spec do_broadcast(:dispatch | :pub_sub | :both, binary(), map()) :: :ok

      defp do_broadcast(:both, channel, %{} = message),
        do: Enum.each(~w|pub_sub dispatch|a, &do_broadcast(&1, channel, message))

      defp do_broadcast(:dispatch, channel, %{} = message) do
        Registry.dispatch(Envio.Registry, fq_channel(channel), fn entries ->
          for {pid, {:dispatch, {module, function}}} <- entries do
            try do
              apply(module, function, [message])
            catch
              kind, reason ->
                # formatted = Exception.format(kind, reason, __STACKTRACE__)
                formatted = Exception.format(kind, reason)
                Logger.error("#{__MODULE__}.broadcast/2 failed with #{formatted}")
            end
          end
        end)
      end

      defp do_broadcast(:pub_sub, channel, %{} = message) do
        Registry.dispatch(Envio.Registry, fq_channel(channel), fn entries ->
          for {pid, {:pub_sub, _}} <- entries, do: send(pid, {:envio, {channel, message}})
        end)
      end

      ##########################################################################

      @spec fq_channel(atom() | binary()) :: binary()
      defp fq_channel(channel), do: Envio.Utils.fq_name(__MODULE__, channel)
    end
  end
end
