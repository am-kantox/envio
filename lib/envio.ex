defmodule Envio do
  @moduledoc """
  Main interface to Envio.

  Provides handy functions to publish messages, subscribe to messages, etc.
  """

  @doc """
  Get list of active channels.
  """
  @spec channels() :: list(%Envio.Channel{})
  def channels do
    Envio.Channels.all()
  end
end
