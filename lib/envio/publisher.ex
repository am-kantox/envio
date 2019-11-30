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
    {manager, opts} = Keyword.pop(opts, :manager, :registry)

    manager = Module.concat(["Envio", "Publishers", Macro.camelize("#{manager}")])

    quote location: :keep, generated: true do
      require Logger

      @behaviour Envio.Publisher

      @channel unquote(opts)[:channel]

      use unquote(manager), unquote(opts)

      @impl Envio.Publisher
      def broadcast(channel, %{} = message) when is_binary(channel) or is_atom(channel),
        do: do_broadcast("#{channel}", message)

      if is_binary(@channel) or is_atom(@channel) do
        @spec broadcast(message :: map()) :: :ok
        def broadcast(%{} = message), do: broadcast(@channel, message)
      end

      ##########################################################################

      defoverridable broadcast: 2
    end
  end
end
