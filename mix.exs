defmodule Esad.MixProject do
  use Mix.Project

  def project do
    [
      app: :esad,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Esad.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.5"},
      {:httpoison, "~> 2.2"}
    ]
  end
end
