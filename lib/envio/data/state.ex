defmodule Envio.State do
  @moduledoc """
  Global Envio state.
  """

  defstruct channels: [],
            subscriptions: %{},
            messages: []
end
