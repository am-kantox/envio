defmodule Envio.Test do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  doctest Envio

  setup_all do
    on_exit(fn ->
      IO.inspect(Envio.Channels.state(), label: "\n\nChannels")
    end)

    :ok
  end

  test "#dispatch with default channel" do
    assert capture_io(fn ->
             Spitter.spit(%{bar: %{baz: 42}, long: "blah blah blah blah blah blah blah blah"})
           end) ==
             ~s|Sucked: %{bar: %{baz: 42}, long: "blah blah blah blah blah blah blah blah"}\n|
  end

  test "#dispatch with explicit channel" do
    assert capture_io(fn ->
             Spitter.spit(:foo, %{bar: %{baz: 42}})
           end) == "Sucked: %{bar: %{baz: 42}}\n"
  end

  test "#pub_sub with initial channels" do
    assert capture_io(fn ->
             with {:ok, _pid} <- PubSucker.start_link() do
               Spitter.spit(:foo, %{bar: %{baz: 42}})
               # to allow message delivery delay
               Process.sleep(100)
               GenServer.stop(PubSucker)
             end
           end) =~ ~r/PubSucked: {%{bar: %{baz: 42}}/
  end

  test "#pub_sub with initial channels and existing GenServer" do
    assert capture_io(fn ->
             with {:ok, _pid} <- ExistingGenServer.start_link() do
               Spitter.spit(:foo, %{bar: %{baz: 42}})
               # to allow message delivery delay
               Process.sleep(100)
               GenServer.stop(ExistingGenServer)
             end
           end) =~ ~r/PubSucked: {%{bar: %{baz: 42}}/
  end

  test "#pub_sub with incomplete declaration raises" do
    assert_raise Envio.InconsistentUsing,
                 ~r|Missing: \[:start_link\]|,
                 fn ->
                   defmodule IncompleteGenServer do
                     use Envio.Subscriber, as: :barebone
                     use GenServer
                     def init(init_arg), do: {:ok, init_arg}
                   end
                 end
  end

  test "#pub_sub with late subscribe" do
    assert capture_io(fn ->
             with {:ok, _pid} <- PubSucker.start_link() do
               PubSucker.subscribe(%Envio.Channel{source: Spitter, name: :main})

               Spitter.spit(:main, %{
                 bar: %{baz: 42},
                 long: "blah blah blah blah blah blah blah blah"
               })

               # to allow message delivery delay
               Process.sleep(500)
               GenServer.stop(PubSucker)
             end
           end) =~ ~r/PubSucked: {%{bar: %{baz: 42}, long/
  end
end
