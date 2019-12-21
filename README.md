# ![Logo](/stuff/logo-48x48.png?raw=true) Envío

[![CircleCI](https://circleci.com/gh/am-kantox/envio.svg?style=svg)](https://circleci.com/gh/am-kantox/envio)     **application-wide registry with handy helpers to ease dispatching**

## Installation

Simply add `envio` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:envio, "~> 0.3"}
  ]
end
```

## Usage

### Simple publisher

Use `Envio.Publisher` helper to scaffold the registry publisher. It provides
`broadcast/2` helper (and `brodcast/1` if the default channel is set.)

```elixir
defmodule Spitter.Registry do
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
  dispatch: %Envio.Channel{source: Spitter.Registry, name: :foo}
)
```

`Sucker.suck/1` will be called with a payload.

### PubSub subscriber ([`pub_sub`](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub))

Use `Envio.Subscriber` helper to scaffold the registry subscriber. Implement
`handle_envio/2` for custom message handling. The default implementation
collects last 10 messages in it’s state.

```elixir
defmodule PubSucker do
  use Envio.Subscriber, channels: [{Spitter.Registry, :foo}]

  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "PubSucked")
    {:noreply, state}
  end
end
```

### Phoenix.PubSub subscriber [`:phoenix_pub_sub`](https://hexdocs.pm/phoenix_pubsub)

Use `manager: :phoenix_pub_sub` for distributed message broadcasting. The implementation below subscribes to `"main"` channel in the distributed OTP environment and prints out each subsequent incoming message to standard output.

```elixir
defmodule Pg2Sucker do
  use Envio.Subscriber, channels: ["main"], manager: :phoenix_pub_sub

  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "Received")
    {:noreply, state}
  end
end
```

The publisher this subscriber might be listening to would look like

```elixir
defmodule Pg2Spitter do
  use Envio.Publisher, manager: :phoenix_pub_sub, channel: "main"
  def spit(channel, what), do: broadcast(channel, what)
  def spit(what), do: broadcast(what)
end
```

## Changelog

* `0.8.0` → `Phoenix.PubSub` support (+ backend)

* `0.5.0` → removed a dependency from `Slack` package

* `0.4.0` → better docs and other enhancements

* `0.3.0` → `Envio.Backend` and infrastructure for backends; `Slack` as an example.

## ToDo

* Back pressure with [`GenStage`](https://hexdocs.pm/gen_stage/GenStage.html)
for `:dispatch` kind of delivery;
* Set of backends for easy delivery (_slack_, _redis_, _rabbit_, etc.)

## [Documentation](https://hexdocs.pm/envio)
