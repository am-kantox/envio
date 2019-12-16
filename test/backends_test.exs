defmodule Envio.Backends.Test do
  use ExUnit.Case, async: true
  doctest Envio.Backends

  test "#pub_sub with registry" do
    Spitter.Registry.spit(:backends, %{bar: 42, pid: self()})
    assert_receive :on_envio_called, 1_000
  end

  test "#pub_sub with pg2" do
    Spitter.PG2.spit("main", %{bar: 42, pid: self()})
    assert_receive :on_envio_called, 1_000
  end
end
