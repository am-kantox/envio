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
      %{id: Envio.PG2, start: {Phoenix.PubSub.PG2, :start_link, [[name: Envio.PG2]]}},
      %{id: Envio.Channels, start: {Envio.Channels, :start_link, []}},
      %{id: Envio.Backends, start: {Envio.Backends, :start_link, []}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
