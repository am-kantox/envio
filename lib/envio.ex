defmodule Envio do
  @moduledoc """
  Main interface to Envio.

  Provides handy functions to publish messages, subscribe to messages, etc.
  """

  @spec register(atom() | {atom(), atom()}, list({atom(), Envio.Channel.t()})) ::
          :ok | {:error, {:already_registered, Envio.Channel.t()}}
  def register(host, channels), do: Envio.Channels.register(host, channels)
end
