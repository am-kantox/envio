defmodule Envio.InconsistentUsing do
  @moduledoc """
  An exception to be thrown when an attempt to use scaffolding is inconsistent.

  For instance, whether the call to `use Envio.Subscriber/1` has no valid `GenServer` defined.
  """

  defexception [:who, :reason, :message]

  def exception(opts) do
    message = """
      Inconsistent call to `use #{opts[:who]}`.
      Reason:
          #{opts[:reason]}.
    """

    %Envio.InconsistentUsing{who: opts[:who], reason: opts[:reason], message: message}
  end
end
