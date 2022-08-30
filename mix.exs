defmodule ExDuck.MixProject do
  use Mix.Project

  @github "https://github.com/sdball/ex_duck"
  @version "0.1.3"

  def project do
    [
      app: :ex_duck,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: "ExDuck allows you to query the DuckDuckGo Instant Answer API. Can convert answer results to markdown.",
      deps: deps(),
      name: "ExDuck",
      source_url: @github,
      package: package(),
      docs: docs(),
    ]
  end

  defp deps do
    [
      {:req, "~> 0.3.0"},
      {:abacus, "~> 2.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @github,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "LICENSE",
      ],
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github
      }
    ]
  end
end
