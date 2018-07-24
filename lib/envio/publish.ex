defmodule Envio.Publish do
  @moduledoc """
  Publisher interface.

  It manages all the channels currently existing in the system.
  """

  @doc """
  The callback to publish stuff to `Envio`.
  """
  @callback broadcast(binary() | atom(), map()) :: :ok | {:error, any()}

  defmacro __using__(opts \\ []) do
    quote do
      require Logger

      @behaviour Envio.Publish
      @namespace Macro.underscore(__MODULE__)
      @registry_kind Keyword.get(unquote(opts), :type, :dispatch)

      @fq_joiner "."

      @impl true
      def broadcast(channel, %{} = message) when is_atom(channel),
        do: channel |> Atom.to_string() |> broadcast(message)

      @impl true
      def broadcast(channel, %{} = message) when is_binary(channel),
        do: do_broadcast(@registry_kind, channel, message)

      defoverridable broadcast: 2

      ##########################################################################

      @spec do_broadcast(:dispatch | :pub_sub, binary(), map()) :: any()
      defp do_broadcast(:dispatch, channel, %{} = message) do
        Registry.dispatch(Envio.Registry, fq_channel(channel), fn entries ->
          for {pid, {module, function}} <- entries do
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
          for {pid, _} <- entries, do: send(pid, {:envio, message})
        end)
      end

      ##########################################################################

      @spec fq_channel(binary()) :: binary()
      defp fq_channel(channel) when is_binary(channel),
        do: Enum.join([@namespace, channel], @fq_joiner)
    end
  end
end
