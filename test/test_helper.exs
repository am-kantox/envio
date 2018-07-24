defmodule Spitter do
  use Envio.Publisher, channel: :main
  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end

defmodule Sucker do
  def suck(what), do: IO.inspect(what, label: "Sucked")
end

defmodule PubSucker do
  use Envio.Subscriber, channels: [{Spitter, :foo}]
  def handle_envio(message, state),
    do: IO.inspect({message, state}, label: "PubSucked")
end

Envio.register({Sucker, :suck}, dispatch: %Envio.Channel{source: Spitter, name: :foo})
Envio.register({Sucker, :suck}, dispatch: %Envio.Channel{source: Spitter, name: "main"})

ExUnit.start()
