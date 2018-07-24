defmodule Envio.Utils do
  @moduledoc false

  @fq_joiner "."

  @spec fq_name(binary() | {atom(), atom() | binary()}) :: binary()
  def fq_name(fq_name) when is_binary(fq_name), do: fq_name
  def fq_name({namespace, channel}), do: fq_name(namespace, channel)

  def fq_name(namespace, channel) when is_binary(namespace) and is_binary(channel),
    do: Enum.join([namespace, channel], @fq_joiner)

  @spec fq_name(atom() | binary(), atom() | binary()) :: binary()
  def fq_name(namespace, channel) when is_binary(namespace) and is_binary(channel),
    do: Enum.join([namespace, channel], @fq_joiner)

  def fq_name(namespace, channel) when is_atom(namespace),
    do: fq_name(Macro.underscore(namespace), channel)

  def fq_name(namespace, channel) when is_atom(channel),
    do: fq_name(namespace, Atom.to_string(channel))
end
