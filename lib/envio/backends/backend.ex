defmodule Envio.Backend do
  @moduledoc """
  The behaviour to be implemented for all the backends.
  """
  # @moduledoc authors: ["Aleksei Matiushkin"], since: "0.3.0"

  @doc """
  The callback when the envio is received.
  """
  @callback on_envio(message :: %{required(:atom) => term()}, meta :: %{required(:atom) => term()}) :: {:ok, term()} | {:error, term()}
end
