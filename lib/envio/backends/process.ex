defmodule Envio.Process do
  @moduledoc false

  @behaviour Envio.Backend

  @impl Envio.Backend
  def on_envio(%{} = message, %{callback: destination}),
    do: {:ok, Process.send(destination, message, [])}

  @impl Envio.Backend
  def on_envio(%{} = _message, _meta),
    do: {:error, :no_callback_in_envio}
end
