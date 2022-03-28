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

  test "process backend" do
    {:ok, pid} = Envio.ProcessBackendHandler.start_link()
    Spitter.Registry.spit(:process, %{bar: 42, callback: self()})
    assert_receive :on_envio_called, 1_000
    GenServer.stop(pid)
  end

  test "runtime options" do
    System.put_env("SLACK_ENVIO_HOOK_URL", "url")
    assert %{hook_url: "url"} = Envio.Slack.Handler.default_options()
  end
end
