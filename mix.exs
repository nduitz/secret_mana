defmodule SecretMana.MixProject do
  use Mix.Project

  @version "0.0.5"
  @source_url "https://github.com/nduitz/secret_mana"

  def project do
    [
      app: :secret_mana,
      version: @version,
      elixir: "~> 1.17",
      description: "Mix tasks for installing and invoking age",
      package: [
        links: %{
          "GitHub" => @source_url,
          "age" => "https://github.com/FiloSottile/age"
        },
        licenses: ["MIT"]
      ],
      docs: [
        main: "SecretMana",
        source_url: @source_url,
        source_ref: "v#{@version}",
        extras: ["CHANGELOG.md"]
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, erl_tar: :optional, inets: :optional, ssl: :optional],
      mod: {SecretMana, []},
      env: [default: []]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mock, "~> 0.3.9", only: :test},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.11"}
    ]
  end
end
