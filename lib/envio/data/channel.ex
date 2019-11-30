defmodule Envio.Channel do
  @moduledoc """
  Channel description.
  """

  defstruct ~w|source name|a

  @typedoc "Channel data stored as a struct"
  @type t :: %__MODULE__{
          source: binary() | atom(),
          name: binary() | atom()
        }

  @spec fq_name({binary() | atom(), binary() | atom()} | t()) :: binary()
  def fq_name({source, name}),
    do: fq_name(%Envio.Channel{source: source, name: name})

  def fq_name(%Envio.Channel{source: source, name: name}),
    do: Envio.Utils.fq_name(source, name)
end
