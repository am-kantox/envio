defmodule Envio.Publisher do
  @moduledoc """
  Publisher interface.

  It manages all the channels currently existing in the system.
  """

  @doc """
  The callback to publish stuff to `Envio`.
  """
  @callback broadcast(binary() | atom(), map()) :: :ok

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      require Logger

      @behaviour Envio.Publisher

      @registry_kind Keyword.get(opts, :type, :both)
      @channel opts[:channel]

      @impl true
      def broadcast(channel, %{} = message) when is_binary(channel),
        do: do_broadcast(@registry_kind, channel, message)

      @impl true
      def broadcast(channel, %{} = message) when is_atom(channel),
        do: channel |> Atom.to_string() |> broadcast(message)

      if is_binary(@channel) or is_atom(@channel),
        do: def(broadcast(%{} = message), do: broadcast(@channel, message))

      defoverridable broadcast: 2

      ##########################################################################

      @spec do_broadcast(:dispatch | :pub_sub | :both, binary(), map()) :: any()

      defp do_broadcast(:both, channel, %{} = message),
        do: Enum.each(~w|pub_sub dispatch|a, &do_broadcast(&1, channel, message))

      defp do_broadcast(:dispatch, channel, %{} = message) do
        Registry.dispatch(Envio.Registry, fq_channel(channel), fn entries ->
          for {pid, {:dispatch, {module, function}}} <- entries do
            try do
              apply(module, function, [message])
            catch
              kind, reason ->
                formatted = Exception.format(kind, reason, __STACKTRACE__)
                Logger.error("#{__MODULE__}.broadcast/2 failed with #{formatted}")
            end
          end
        end)
      end

      defp do_broadcast(:pub_sub, channel, %{} = message) do
        Registry.dispatch(Envio.Registry, fq_channel(channel), fn entries ->
          for {pid, {:pub_sub, _}} <- entries, do: send(pid, {:envio, {channel, message}})
        end)
      end

      ##########################################################################
      @spec fq_channel(atom() | binary()) :: binary()
      defp fq_channel(channel), do: Envio.Utils.fq_name(__MODULE__, channel)
    end
  end
end
