defmodule Envio.State do
  @moduledoc """
  Global Envio state.
  """

  defstruct subscriptions: %{},
            messages: []
end
