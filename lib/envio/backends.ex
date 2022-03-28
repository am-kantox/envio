defmodule Envio.Backends do
  @moduledoc false

  use Supervisor

  require Logger

  @backends Application.compile_env(:envio, :backends, [])

  @children Enum.flat_map(@backends, fn {module, consumers} ->
              handler_module = Module.concat(module, Handler)

              Enum.map(consumers, fn {consumer, opts} ->
                consumer =
                  case consumer do
                    [_ | _] -> consumer
                    _ -> [consumer]
                  end

                {manager, opts} = Keyword.pop(opts, :manager, :registry)

                contents =
                  quote do
                    use Envio.Subscriber,
                      module: unquote(handler_module),
                      manager: unquote(manager),
                      channels: unquote(consumer)

                    @spec default_options :: map()
                    def default_options do
                      unquote(opts)
                      |> Enum.map(fn {k, v} ->
                        {k, Envio.Utils.config_value(v).()}
                      end)
                      |> Map.new()
                    end

                    @impl Envio.Subscriber
                    def handle_envio(message, state) do
                      {meta, message} = Map.pop(message, :__meta__, %{})

                      unquote(module).on_envio(message, Map.merge(default_options(), meta))

                      {:noreply, state}
                    end
                  end

                {:module, backend, _, _} =
                  Module.create(handler_module, contents, Macro.Env.location(__ENV__))

                {backend, []}
              end)
            end)

  @doc """
  Starts a new channels bucket.
  """
  @spec start_link(args :: keyword()) :: Supervisor.on_start()
  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_arg),
    do: Supervisor.init(@children, strategy: :one_for_one)
end
