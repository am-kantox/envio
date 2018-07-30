defmodule Envio.Backends.Test do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  doctest Envio.Backends

  test "#pub_sub with backend" do
    Spitter.spit(:backends, %{bar: 42, pid: self()})
    Process.sleep(1_000)
    assert_received :on_envio_called
  end
end
