import Config

config :envio, :binary_value, "FOO"
config :envio, :env_value, {:system, "FOO"}

config :envio, :backends, %{
  # Envio.Slack => %{
  #   {Spitter.Registry, :main} => [
  #     hook_url: {:system, "SLACK_ENVIO_HOOK_URL"}
  #   ]
  # },
  Envio.IOBackend => %{{Spitter.Registry, :backends} => []}
}
