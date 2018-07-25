defmodule Envio.Test do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  doctest Envio

  test "#dispatch with default channel" do
    assert capture_io(fn ->
             Spitter.spit(%{bar: 42})
           end) == "Sucked: %{bar: 42}\n"
  end

  test "#dispatch with explicit channel" do
    assert capture_io(fn ->
             Spitter.spit(:foo, %{bar: 42})
           end) == "Sucked: %{bar: 42}\n"
  end

  test "#pub_sub with initial channels" do
    assert capture_io(fn ->
             with {:ok, _pid} <- PubSucker.start_link() do
               Spitter.spit(:foo, %{bar: 42})
               # to allow message delivery delay
               Process.sleep(100)
               GenServer.stop(PubSucker)
             end
           end) =~ ~r/PubSucked: {%{bar: 42}/
  end

  test "#pub_sub with late subscribe" do
    assert capture_io(fn ->
             with {:ok, _pid} <- PubSucker.start_link() do
               PubSucker.subscribe(%Envio.Channel{source: Spitter, name: :main})
               Spitter.spit(:main, %{bar: 42})
               # to allow message delivery delay
               Process.sleep(100)
               GenServer.stop(PubSucker)
             end
           end) =~ ~r/PubSucked: {%{bar: 42}/
  end
end
