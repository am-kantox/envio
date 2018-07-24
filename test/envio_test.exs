defmodule Envio.Test do
  use ExUnit.Case
  doctest Envio

  setup_all do
    with {:ok, pid} <- PubSucker.start_link() do
      %{pub_sucker: pid}
    end
  end

  test "allows registering and dispatching" do
    Spitter.spit(%{bar: 42})
    Spitter.spit(:foo, %{bar: 42})
    IO.inspect(Envio.Channels.state, label: "State")
  end
end
