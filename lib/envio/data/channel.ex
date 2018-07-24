defmodule Envio.Channel do
  @moduledoc """
  Channel description.
  """

  defstruct ~w|source name|a

  def fq_name(%Envio.Channel{source: source, name: name}),
    do: Envio.Utils.fq_name(source, name)
end
