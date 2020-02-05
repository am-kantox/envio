defmodule Envio.Backend do
  @moduledoc """
  The behaviour to be implemented for all the backends.
  """

  @doc """
  The callback when the envio is received.
  """
  @callback on_envio(
              message :: %{required(:atom) => term()},
              meta :: %{required(:atom) => term()}
            ) :: {:ok, term()} | {:error, term()}
end
