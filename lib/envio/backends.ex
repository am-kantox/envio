defmodule Envio.Backends do
  @moduledoc false

  require Logger

  @backends Application.get_env(:envio, :backends, [])

  Enum.each(@backends, fn {module, consumers} ->
    handler_module = Module.concat(module, Handler)

    Enum.each(consumers, fn {consumer, opts} ->
      consumer =
        case consumer do
          [_|_] -> consumer
          _ -> [consumer]
        end

      contents =
        quote do
          use Envio.Subscriber, module: unquote(handler_module), channels: unquote(consumer)

          def handle_envio(message, state) do
            apply(unquote(module), :on_envio, [Map.put(message, :meta, Enum.into(unquote(opts), %{}))])
            {:noreply, state}
          end
        end

      {:module, _backend, _, _} =
        Module.create(handler_module, contents, Macro.Env.location(__ENV__))

      # DynamicSupervisor.start_child(Envio.Backends.Supervisor, {Envio.Slack.Handler, []})

    end)
  end)
end
