defmodule CodeMantra.MixProject do
  use Mix.Project

  def project do
    [
      app: :code_mantra,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {CodeMantra.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
