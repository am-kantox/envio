defmodule Envio.Backends.Test do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  doctest Envio.Backends

  test "#pub_sub with backend" do
    assert capture_io(fn ->
      Spitter.spit(:backends, %{bar: 42})
      # to allow message delivery delay
      Process.sleep(1_000)
    end) == "" # message is not captured, just printed
  end
end
