defmodule Spitter do
  use Envio.Publish
  def spit(what), do: broadcast(:foo, what)
end

defmodule Sucker do
  def suck(what), do: IO.inspect(what, label: "Sucked")
end

{:ok, _} = Registry.register(Envio.Registry, "spitter.foo", {Sucker, :suck})

ExUnit.start()
