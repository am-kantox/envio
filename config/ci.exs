import Config

config :envio, :binary_value, "FOO"
config :envio, :env_value, {:system, "FOO"}

config :envio, :backends, %{
  Envio.IOBackend.Registry => %{{Spitter.Registry, :backends} => []},
  Envio.IOBackend.PG2 => %{"main" => [manager: :phoenix_pub_sub]}
}
