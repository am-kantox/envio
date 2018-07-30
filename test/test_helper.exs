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

defmodule Envio.IOBackend do
  @moduledoc false

  @behaviour Envio.Backend

  @impl true
  def on_envio(message, meta) do
    IO.inspect({message, message[:pid]}, label: "[★Envío★]")
    Process.send(message[:pid], :on_envio_called, [])
  end
end

ExUnit.start()

