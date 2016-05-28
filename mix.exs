defmodule Scarab.Mixfile do
  use Mix.Project

  def project do
    [app: :scarab,
     version: "0.1.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:ex_aws, "~> 0.4", optional: true},
     {:poison, "~> 1.2", only: [:dev, :test]},
     {:httpoison, "~> 0.7", only: [:dev, :test]}]
  end
end
