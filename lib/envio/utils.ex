defmodule Envio.Utils do
  @moduledoc """
  Multipurpose utils, required for the _Envío_ proper functioning, like:

  * `fq_name` to construct fully-qualified names for channels to prevent clashes
  """

  @fq_joiner "."

  @doc """
  Produces a fully-qualified name out of namespace in a form
    of a module name atom and a method name (atom or binary.)

  ## Examples

      iex> Envio.Utils.fq_name("foo")
      "foo"
      iex> Envio.Utils.fq_name({Foo.Bar, "baz"})
      "foo/bar.baz"
      iex> Envio.Utils.fq_name(Foo.Bar, "baz")
      "foo/bar.baz"
      iex> Envio.Utils.fq_name(Foo.Bar, :baz)
      "foo/bar.baz"
      iex> Envio.Utils.fq_name("Foo.Bar", "baz")
      "Foo.Bar.baz"
  """
  @spec fq_name(binary() | atom() | {atom(), atom() | binary()}, nil | atom() | binary()) :: binary()
  def fq_name(namespace_or_name, name_or_nil \\ nil)
  def fq_name(fq_name, nil) when is_binary(fq_name), do: fq_name
  def fq_name({namespace, channel}, nil), do: fq_name(namespace, channel)

  def fq_name(namespace, channel) when is_binary(namespace) and is_binary(channel),
    do: Enum.join([namespace, channel], @fq_joiner)

  def fq_name(namespace, channel) when is_atom(namespace),
    do: fq_name(Macro.underscore(namespace), channel)

  def fq_name(namespace, channel) when is_atom(channel),
    do: fq_name(namespace, Atom.to_string(channel))
end
