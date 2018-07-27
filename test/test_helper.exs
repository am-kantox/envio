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

  @impl true
  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end

Envio.register({Sucker, :suck}, dispatch: %Envio.Channel{source: Spitter, name: :foo})
Envio.register({Sucker, :suck}, dispatch: %Envio.Channel{source: Spitter, name: "main"})

ExUnit.start()

######
# What I am doing to start the process:
#
# DynamicSupervisor.start_child(Envio.Backends.Supervisor, {Envio.Slack.Handler, []})
# #⇒ {:ok, #PID<0.319.0>}
#
# defmodule Spitter do
#   use Envio.Publisher, channel: :main
#   def spit(channel, what), do: broadcast(channel, what)
#   def spit(what), do: broadcast(what)
# end
#
# Spitter.spit %{title: "YAYAYAYAtitle", text: "text", pretext: "pretext", foo: "baz",
#   long: "https://hooks.slack.com/services/T02FE287L/B7S08G4K1/c7Q6zaaEpxP1HvUiSdt2IFa",
#   foo1: "foo1", foo2: "foo2", level: :warn}
