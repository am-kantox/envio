defmodule Envio.Application do
  @moduledoc false
  use Application

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
      {DynamicSupervisor, strategy: :one_for_one, name: Envio.Backends.Supervisor},
      # %{id: Envio.Backends.Supervisor, start: {DynamicSupervisor, :start_link, [strategy: :one_for_one, name: Envio.Backends.Supervisor]}},
      %{id: Envio.Channels, start: {Envio.Channels, :start_link, []}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
