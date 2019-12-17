defmodule Envio.Publishers.Registry do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    {adapter, _opts} = Keyword.pop(opts, :adapter, :pub_sub)

    quote location: :keep, generated: true do
      @adapter unquote(adapter)

      @spec do_broadcast(binary(), map()) :: :ok
      defp do_broadcast(channel, %{} = message),
        do: do_broadcast(@adapter, channel, message)

      @spec do_broadcast(:dispatch | :pub_sub | :both, binary(), map()) :: :ok

      defp do_broadcast(:both, channel, %{} = message),
        do: Enum.each(~w|pub_sub dispatch|a, &do_broadcast(&1, channel, message))

      defp do_broadcast(:dispatch, channel, %{} = message) do
        {channel, _} = Envio.Utils.channel_message(__MODULE__, channel, message)

        Registry.dispatch(Envio.Registry, channel, fn entries ->
          for {pid, {:dispatch, {module, function}}} <- entries do
            try do
              apply(module, function, [message])
            catch
              kind, reason ->
                # formatted = Exception.format(kind, reason, __STACKTRACE__)
                formatted = Exception.format(kind, reason)
                Logger.error("#{__MODULE__}.broadcast/2 failed with #{formatted}")
            end
          end
        end)
      end

      defp do_broadcast(:pub_sub, channel, %{} = message) do
        {channel, message} = Envio.Utils.channel_message(__MODULE__, channel, message)

        Registry.dispatch(Envio.Registry, channel, fn entries ->
          for {pid, {:pub_sub, _}} <- entries,
              do: send(pid, message)
        end)
      end
    end
  end
end
