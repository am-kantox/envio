defmodule Envio.MixProject do
  use Mix.Project

  @app :envio
  @app_name "envio"
  @version "0.4.3"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      package: package(),
      xref: [exclude: []],
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Envio.Application, []},
      extra_applications: [:logger, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # backends
      {:slack, "~> 0.14"},
      {:iteraptor, "~> 1.0"},
      {:jason, "~> 1.0"},
      # utilities
      {:credo, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev, override: true}
    ]
  end

  defp description do
    """
    The application-wide registry with handy helpers to ease dispatching.
    """
  end

  defp package do
    [
      name: @app,
      files: ~w|config lib mix.exs README.md|,
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/am-kantox/#{@app}",
        "Docs" => "https://hexdocs.pm/#{@app}"
      }
    ]
  end

  defp docs() do
    [
      main: @app_name,
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      logo: "stuff/logo-48x48.png",
      source_url: "https://github.com/am-kantox/#{@app}",
      extras: [
        "stuff/#{@app_name}.md",
        "stuff/backends.md"
      ],
      groups_for_modules: [
        # Envio

        "Scaffold Helpers": [
          Envio.Publisher,
          Envio.Subscriber
        ],
        "Internal Data": [
          Envio.Channel,
          Envio.State
        ]
      ]
    ]
  end
end
