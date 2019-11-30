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
  @spec fq_name(binary() | atom() | {atom(), atom() | binary()}, nil | atom() | binary()) ::
          binary()
  def fq_name(namespace_or_name, name_or_nil \\ nil)
  def fq_name(fq_name, nil) when is_binary(fq_name), do: fq_name
  def fq_name({namespace, channel}, nil), do: fq_name(namespace, channel)

  def fq_name(namespace, channel) when is_binary(namespace) and is_binary(channel),
    do: Enum.join([namespace, channel], @fq_joiner)

  def fq_name(namespace, channel) when is_atom(namespace),
    do: fq_name(Macro.underscore(namespace), channel)

  def fq_name(namespace, channel) when is_atom(channel),
    do: fq_name(namespace, Atom.to_string(channel))

  ##############################################################################

  @doc """
  Returns the anonymous function that either loads the system environment
  variable or simply returns the value statically loaded from config file.

  ## Examples

      iex> # config :envio, :binary_value, "FOO"
      iex> Envio.Utils.config_value(Application.get_env(:envio, :binary_value)).()
      "FOO"

      iex> # config :envio, :env_value, {:system, "FOO"}
      iex> System.put_env("FOO", "42")
      iex> Envio.Utils.config_value(Application.get_env(:envio, :env_value)).()
      "42"
  """
  @spec config_value(input :: binary() | {:system, binary()}) :: term()
  def config_value(nil), do: fn -> nil end
  def config_value({:system, env_var}), do: fn -> System.get_env(env_var) end
  def config_value(var) when is_binary(var), do: fn -> var end

  ##############################################################################

  @doc """
  Fetches the value from the map by given key _and_ returns both the value and
  the map without this key.

  ## Examples

      iex> Envio.Utils.get_delete(%{foo: :bar, baz: 42}, :foo)
      {:bar, %{baz: 42}}
      iex> Envio.Utils.get_delete(%{baz: 42}, :foo)
      {nil, %{baz: 42}}
      iex> Envio.Utils.get_delete(%{baz: 42}, :foo, :bar)
      {:bar, %{baz: 42}}
  """
  @spec get_delete(input :: map(), key :: atom(), default :: term()) :: term()
  def get_delete(%{} = input, key, default \\ nil) do
    case Map.fetch(input, key) do
      {:ok, value} -> {value, Map.delete(input, key)}
      :error -> {default, input}
    end
  end

  ##############################################################################

  @doc """
  Safely converts any term to binary.

  ## Examples

      iex> Envio.Utils.smart_to_binary("foo")
      "foo"
      iex> Envio.Utils.smart_to_binary(42)
      "42"
      iex> Envio.Utils.smart_to_binary(%{foo: :bar, baz: 42})
      "%{baz: 42, foo: :bar}"
      iex> Envio.Utils.smart_to_binary([foo: :bar, baz: 42])
      "[foo: :bar, baz: 42]"
  """
  @spec smart_to_binary(input :: term()) :: binary()
  def smart_to_binary(list) when is_list(list), do: inspect(list)
  def smart_to_binary(string) when is_binary(string), do: string

  def smart_to_binary(whatever) do
    if String.Chars.impl_for(whatever), do: to_string(whatever), else: inspect(whatever)
  end

  @doc false
  def subscriber_finalizer(env, _bytecode) do
    interface = env.module.__info__(:functions)
    mandatory = ~w|start_link handle_envio handle_info|a
    presented = interface |> Keyword.take(mandatory) |> Keyword.keys()

    unless 3 <= Enum.count(presented) do
      raise Envio.InconsistentUsing,
        who: env.module,
        reason: ~s"""
        The module #{env.module} does not provide one of mandatory functions for Subscriber.

          Required: #{inspect(mandatory)}.
          Missing: #{inspect(mandatory -- presented)}.
        """
    end
  end

  @spec format_envio(channel :: binary(), message :: map()) :: {:envio, {binary(), map()}}
  defp format_envio(channel, message), do: {:envio, {channel, message}}

  @spec channel_message(module :: module(), channel :: binary(), message :: map()) ::
          {binary(), {:envio, {binary(), map()}}}
  def channel_message(module, channel, message) do
    channel = fq_name(module, channel)
    {channel, format_envio(channel, message)}
  end
end
