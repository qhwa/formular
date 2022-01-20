defmodule Formular.MixProject do
  use Mix.Project

  def project do
    [
      app: :formular,
      description: "A simple extendable DSL evaluator.",
      version: "0.3.1",
      elixir: ">= 1.10.0",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Formular.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:git_hooks, "~> 0.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:git_hub_actions, "~> 0.1", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:benchee, "~> 1.0.1", only: :dev}
    ]
  end

  defp docs do
    [
      main: "Formular"
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: [
        "qhwa <qhwa@pnq.cc>"
      ],
      source_url: "https://github.com/qhwa/formular",
      links: %{
        Github: "https://github.com/qhwa/formular"
      },
      files: ~w[
        lib mix.exs
      ]
    ]
  end
end
