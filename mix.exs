defmodule Caustic.MixProject do
  use Mix.Project

  def project do
    [
      app: :caustic,
      name: "Caustic",
      source_url: "https://github.com/agro1986/caustic",
      version: "0.1.20",
      elixir: "~> 1.7",
      description: description(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    An Elixir library of useful methods used in various cryptocurrencies (Bitcoin, Ethereum, etc.).
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Agro Rachmatullah"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/agro1986/caustic"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19.1", only: :dev},
      {:earmark, "~> 1.2.6", only: :dev},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
