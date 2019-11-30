Envio.register({Sucker, :suck}, dispatch: %Envio.Channel{source: Spitter.Registry, name: :foo})
Envio.register({Sucker, :suck}, dispatch: %Envio.Channel{source: Spitter.Registry, name: "main"})

ExUnit.start()
