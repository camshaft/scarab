defmodule Scarab.Mixfile do
  use Mix.Project

  def project do
    [app: :scarab,
     description: "content-addressable file storage",
     version: "0.1.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:con_cache, ">= 0.0.0", optional: true},
     {:ex_aws, ">= 0.0.0", optional: true},
     {:poison, "~> 1.2", only: [:dev, :test]},
     {:httpoison, "~> 0.7", only: [:dev, :test]},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/scarab"}]
  end
end
