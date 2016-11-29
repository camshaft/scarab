defmodule Scarab.Mixfile do
  use Mix.Project

  def project do
    [app: :scarab,
     description: "content-addressable file storage",
     version: "0.1.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:ex_aws, ">= 0.0.0", optional: true},
     {:poison, "~> 1.2", only: [:dev, :test]},
     {:httpoison, "~> 0.7", only: [:dev, :test]}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/scarab"}]
  end
end
