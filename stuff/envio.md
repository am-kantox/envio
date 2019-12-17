# ![Envío Logo](https://github.com/am-kantox/envio/blob/master/stuff/logo-48x48.png?raw=true)   Envío

**Envío** is basically a `GenEvent²`, the modern idiomatic pub-sub
implementation of event passing.

In a nutshell, **Envío** is a set of handy tools to simplify dealing with Elixir
[`Registry`](https://hexdocs.pm/elixir/master/Registry.html). It includes
the instance of `Registry` to be used out of the box, scaffolds for
producing _publishers_ and _subscribers_.

It is built using “convention over configuration” approach, preserving the whole
low-level control over the registry entries.

Just add the application `:envio` into your list of _extra_ applications
and the default `Envio.Registry` will be started and managed automagically.

```elixir
def application do
  [
    mod: {MyApplication, []},
    extra_applications: ~w|envio ...|a
  ]
end
```

### Creating a publisher

To create a publisher just `use Envio.Publisher` in the module that should
publish messages to the subscribers. Once `use Envio.Publisher` is used,
`broadcast/2` function becomes available. If the optional `channel:`
argument is passed to `use Envio.Publisher`, this channel is considered
the default one and `broadcast/1` function appears to publish directly
to the default channel.

```elixir
defmodule MyPub do
  use Envio.Publisher, channel: :main

  def publish(channel, what), do: broadcast(channel, what)
  def publish(what), do: broadcast(what)
end
```

Another option that might be passed to `use Envio.Publisher` is `manager:`, that might be either `:registry` (default,) or `:phoenix_pub_sub` to use [`Phoenix.PubSub`](https://hexdocs.pm/phoenix_pubsub) for distributed message broadcasting.

### Creating a subscriber

#### ▶ [`:dispatch`](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-dispatcher)

Simply register the handler anywhere in the code:

```elixir
Envio.register(
  {MySub, :on_envio}, # the function of arity 2 must exist
  dispatch: %Envio.Channel{source: MyPub, name: :main}
)
```

As `MyPub` publishes to the `:main` channel, `MySub.on_envio/2` will
be called with a message passed as parameter.

#### ▶ [`:pub_sub`](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub)

Use `Envio.Subscriber` helper to scaffold the registry subscriber. Implement
`handle_envio/2` for custom message handling. The default implementation
collects last `10` messages in it’s state. This amount might be adjusted by
changing `:envio, :subscriber_queue_size` application environment setting.

The implementation below subscribes to `:main` channel provided by `MyPub`
publisher and prints out each subsequent incoming message to standard output.

```elixir
defmodule PubSucker do
  use Envio.Subscriber, channels: [{MyPub, :main}]

  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect({message, state}, label: "Received")
    {:noreply, state}
  end
end
```

#### ▶ [`:phoenix_pub_sub`](https://hexdocs.pm/phoenix_pubsub)

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
