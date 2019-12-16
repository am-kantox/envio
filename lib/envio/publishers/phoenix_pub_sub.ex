defmodule Envio.Publishers.PhoenixPubSub do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    {adapter, _opts} = Keyword.pop(opts, :adapter, :pg2)

    quote location: :keep, generated: true do
      @adapter unquote(adapter)

      @spec do_broadcast(binary(), map()) :: :ok
      defp do_broadcast(channel, %{} = message),
        do: do_broadcast(@adapter, channel, message)

      @spec do_broadcast(:pg2 | :redis | :all, binary(), map()) :: :ok
      defp do_broadcast(:all, channel, %{} = message),
        do: Enum.each(~w|pg2 redis|a, &do_broadcast(&1, channel, message))

      defp do_broadcast(:pg2, channel, %{} = message),
        do: Phoenix.PubSub.broadcast(Envio.PG2, channel, {:envio, {channel, message}})

      defp do_broadcast(:redis, channel, %{} = message) do
        raise "Not implemented"

        Phoenix.PubSub.broadcast(Envio.Redis, channel, message)
      end
    end
  end
end
