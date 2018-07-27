use Mix.Config

config :envio, :binary_value, "FOO"
config :envio, :env_value, {:system, "FOO"}

config :envio, :backends,
  slack: %{
    {Spitter, :slack} => [
      channel: {:system, "SLACK_ENVIO_CHANNEL"},
      key: {:system, "SLACK_ENVIO_KEY"}
    ]
  }
