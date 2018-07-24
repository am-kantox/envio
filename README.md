# ![Logo](/stuff/logo-48x48.png?raw=true) Envío

[![CircleCI](https://circleci.com/gh/am-kantox/envio.svg?style=svg)](https://circleci.com/gh/am-kantox/envio) **    application-wide registry with handy helpers to ease dispatching**

## Installation

Simply add `envio` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:envio, "~> 0.1"}
  ]
end
```

## Usage

### Simple publisher

Use `Envio.Publisher` helper to scaffold the registry publisher. It provides
`broadcast/2` helper (and `brodcast/1` if the default channel is set.)

```elixir
defmodule Spitter do
  use Envio.Publisher, channel: :main

  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end
```

### Simple subscriber ([`dispatch`](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-dispatcher))

Just register your handler anywhere in the code:

```elixir
Envio.register(
  {Sucker, :suck},
  dispatch: %Envio.Channel{source: Spitter, name: :foo}
)
```

`Sucker.suck/1` will be called with a payload.

### PubSub subscriber ([`pub_sub`](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub))

Use `Envio.Subscriber` helper to scaffold the registry subscriber. Implement
`handle_envio/2` for custom message handling. The default implementation
collects last 10 messages in it’s state.

```elixir
defmodule PubSucker do
  use Envio.Subscriber, channels: [{Spitter, :foo}]

  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end
```

## [Documentation](https://hexdocs.pm/envio)
