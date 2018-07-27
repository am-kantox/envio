use Mix.Config

config :envio, :binary_value, "FOO"
config :envio, :env_value, {:system, "FOO"}

config :envio, :backends,
  slack: %{
    {Spitter, :slack} => [
      hook_url: {:system, "SLACK_ENVIO_HOOK_URL"},
      channel: "eventory_debug",
      username: "envío"
    ]
  }
