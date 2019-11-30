# Backends

**Envío** supports configurable backends as subscribers with very little to none
code. It comes with the following backends out of the box:

* `Slack` — a subscriber to _envíos_ that sends all the incoming messages to the preconfigured slack channel
* `IO`, `...`, _more coming_

Backend is basically a supervised `GenServer` that implements `Envio.Backend`
behaviour. Backends, provided by the core are generated based on the configuration.
The typical config looks like this (example for `Envio.Slack`):

```elixir
config :envio, :backends, %{
  Envio.Slack => %{
    {MyPub, :main} => [
      hook_url: {:system, "SLACK_ENVIO_HOOK_URL"}
    ]
  }
}
```
`Envio.Slack`, used as a key, is a name of the module that implements the
`Envio.Backend` behaviour (currently it’s the single function
[`Envio.Backend.on_envio/2`](Envio.Backend.html#c:on_envio/2)
that receives a message when published by the publisher.) The value assigned
to the key is a map of `{Envio.Publisher, :channel}` tuples to the list of
arguments that will be injected into the message under `:meta` key.

When the publisher emits, say,
`%{title: "Pi reminder", text: "Recall pi value now!", pi: 3.14}` _envío_,
the `%{meta: %{hook_url: "my_slack_hook_url"}}` will be merged into the
message for the further processing by the backend. Typically, the backend
will extract this `meta` information out of the message using

```elixir
{meta, message_without_meta} = Utils.get_delete(message, :meta)
```

and use this information for the backend-specific actions (e. g. what channel
to post the message to in the case of Slack.)

### Implementation details

`Slack` backends understands four _predefined_ keys:

* `title` — is treated as title of the message
* `text`, `message` — both are treated as a message body, formatted as `pretext`
* `level` — the message “level” that affects the color of the left bar and the icon.

All other keys are treated as _values_, put as _short_ and _long_ attachments
depending on their length (those longer than 32 symbols take the whole line in
the slack attachments output.)

### Slacking using `Envío`

It has never easier. Once your application uses `Envío` as a publisher,
broadcasting messages to the channel named `my_app/my_module.main_channel`
(the latter means messages are published by `MyApp.MyModule` that has
`use Envio.Publisher, channel: :main_channel`, using `broadcast(message)`,
or you have a generic `pub_sub` publisher registered in `Envio.Registry`
using standard Elixir `Registry` functions,) simply add the following to
the configuration file:

```elixir
config :envio, :backends, %{
  Envio.Slack => %{
    {MyApp.MyModule, :main_channel} => [
      # one might simply put a channel name here as binary,
      #  but I don’t recommend that since it’s kinda credentials
      hook_url: {:system, "SLACK_ENVIO_HOOK_URL"}
    ]
  }
}
```

Well, that’s it. Your application is now Slack-enabled.

### Example from `Envío` tests

To test Envío’s backend functionality I used plain old good `IO.inspect`
backend with `ExUnit.CaptureIO` as a checker:

```elixir
defmodule Envio.IOBackend do
  @moduledoc false

  @behaviour Envio.Backend

  @impl Envio.Backend
  def on_envio(message, meta) do
    IO.inspect(message, label: "[★Envío★]")
  end
end
```

The above is a fully valid backend implementation, that subscribes to the `:backends` channel
of the `Spitter.Registry` ckass defined in `test_helper.exs` (the excerpt is from `test.exs` config):

```elixir
config :envio, :backends, %{
  Envio.IOBackend => %{{Spitter.Registry, :backends} => []}
}
```
Once emitted by `Spitter.Registry`, this message will be published to the standard output:

```elixir
[★Envío★]: %{bar: 42, meta: %{}}
```
