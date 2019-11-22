import Config

config :envio, :binary_value, "FOO"
config :envio, :env_value, {:system, "FOO"}

config :envio, :backends, %{
  Envio.Slack => %{
    {Spitter, :foo} => [
      hook_url: "https://hooks.slack.com/services/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"
    ]
  },
  Envio.IOBackend => %{{Spitter, :backends} => []}
}
