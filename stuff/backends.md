# Backends

**Envío** supports configurable backends as subscribers with very little to none
code. It comes with the following backends out of the box:

* `Slack` — a subscriber to _envíos_ that sends all the incoming messages to
the preconfigured slack channel
* ... _more coming_

Backend is basically a supervised `GenServer` that implements [`Envio.Backend`]
behaviour. Backends, provided by the core are generated based on the configuration.
The typical config looks like this (example for `Slack`):

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
[`Envio.Backend`] behaviour (currently it’s the single function `on_envio/1`
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

and use this information for the backend-specific actions (what channel
to post the message to in the case of Slack.)

