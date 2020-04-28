defmodule Envio.Application do
  @moduledoc false
  use Application

  @spec start(Application.app(), Application.restart_type()) :: Supervisor.on_start()
  def start(_type, _args) do
    children = [
      %{
        id: Envio.Registry,
        start: {
          Registry,
          :start_link,
          [
            [
              keys: :duplicate,
              name: Envio.Registry,
              partitions: System.schedulers_online()
            ]
          ]
        }
      },
      phoenix_pubsub_spec(),
      %{id: Envio.Channels, start: {Envio.Channels, :start_link, []}},
      %{id: Envio.Backends, start: {Envio.Backends, :start_link, []}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp phoenix_pubsub_spec do
    with :ok <- Application.load(:phoenix_pubsub) do
      :phoenix_pubsub
      |> Application.spec(:vsn)
      |> to_string()
      |> Version.compare("2.0.0")
      |> case do
        :lt ->
          %{
            id: Envio.PG2,
            start: {Phoenix.PubSub.PG2, :start_link, [[name: Envio.PG2]]}
          }

        _ ->
          {Phoenix.PubSub, name: Envio.PG2}
      end
    end
  end
end
