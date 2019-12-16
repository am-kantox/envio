defmodule Envio.Subscribers.Registry do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    quote location: :keep, generated: true, bind_quoted: [opts: opts] do
      @channels Keyword.get(opts, :channels, [])

      @spec do_subscribe(channels :: [binary()], state :: Envio.State.t()) :: Envio.State.t()
      def do_subscribe(channels \\ [], state)

      def do_subscribe([], state), do: do_subscribe(@channels, state)

      def do_subscribe(channels, state) do
        subscriptions =
          for {source, channel} <- channels, into: %{} do
            {%Envio.Channel{source: source, name: channel},
             Registry.register(
               Envio.Registry,
               Envio.Channel.fq_name({source, channel}),
               {:pub_sub, __MODULE__}
             )}
          end

        %Envio.State{state | subscriptions: Map.merge(state.subscriptions, subscriptions)}
      end
    end
  end
end
