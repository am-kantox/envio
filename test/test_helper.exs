defmodule Spitter do
  use Envio.Publisher, channel: :main
  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end

defmodule Sucker do
  def suck(what), do: IO.inspect(what, label: "Sucked")
end

{:ok, _} = Registry.register(Envio.Registry, "spitter.foo", {:dispatch, {Sucker, :suck}})
{:ok, _} = Registry.register(Envio.Registry, "spitter.main", {:dispatch, {Sucker, :suck}})

ExUnit.start()
