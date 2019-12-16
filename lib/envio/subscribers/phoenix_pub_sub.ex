defmodule Envio.Subscribers.PhoenixPubSub do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    quote location: :keep, generated: true, bind_quoted: [opts: opts] do
      @adapter Keyword.get(opts, :adapter, :pg2)
      @channels Keyword.get(opts, :channels, [])

      @spec do_subscribe(channels :: [binary()], state :: Envio.State.t()) :: Envio.State.t()
      def do_subscribe(channels \\ [], state)

      def do_subscribe([], state), do: do_subscribe(@channels, state)

      def do_subscribe(channels, state) do
        subscriptions =
          for channel <- channels, into: %{} do
            {%Envio.Channel{source: @adapter, name: channel},
             Phoenix.PubSub.subscribe(Envio.PG2, channel)}
          end

        %Envio.State{state | subscriptions: Map.merge(state.subscriptions, subscriptions)}
      end

      @spec adapter(atom()) :: module()
      defp adapter(:pg2), do: Phoenix.PubSub.PG2
      defp adapter(:redis), do: Phoenix.PubSub.Redis
    end
  end
end
