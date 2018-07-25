defmodule Envio.State do
  @moduledoc """
  Global Envio state. Contains subscriptions, messages
  that were not yet processed and options.
  """

  @typedoc "Internal state of everything amongst Envío."
  @type t :: %__MODULE__{
          subscriptions: map(),
          messages: [term()],
          options: keyword()
        }

  defstruct subscriptions: %{},
            messages: [],
            options: []
end
