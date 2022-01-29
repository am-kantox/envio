import Config

config :envio, :binary_value, "FOO"
config :envio, :env_value, {:system, "FOO"}

config :envio, :backends, %{
  # Envio.Slack => %{
  #   {Spitter.Registry, :main} => [
  #     hook_url: {:system, "SLACK_ENVIO_HOOK_URL"}
  #   ]
  # },
  Envio.IOBackend.Registry => %{{Spitter.Registry, :backends} => []},
  Envio.IOBackend.PG2 => %{"main" => [manager: :phoenix_pub_sub]},
  Envio.Process => %{{Spitter.Registry, :process} => [callback: Envio.ProcessBackendHandler]}
}
