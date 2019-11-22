defmodule Envio.Channel do
  @moduledoc """
  Channel description.
  """

  defstruct ~w|source name|a

  @typedoc "Channel data stored as a struct"
  @type t :: %__MODULE__{
    source: binary(),
    name: binary()
  }

  @spec fq_name(t()) :: binary()
  def fq_name(%Envio.Channel{source: source, name: name}),
    do: Envio.Utils.fq_name(source, name)
end
