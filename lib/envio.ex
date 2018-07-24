defmodule Envio do
  @moduledoc """
  Main interface to Envio.

  Provides handy functions to publish messages, subscribe to messages, etc.
  """

  @doc """
  Get list of active channels.
  """
  @spec subscriptions() :: map()
  def subscriptions do
    Envio.Channels.subscriptions()
  end
end
