defmodule Ikbot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ikbot,
      version: "0.0.1",
      elixir: "~>1.0",
      deps: deps
    ]
  end

  def application do
    [
      applications: [
        :httpotion,
        :hedwig
      ],
      mod: {Ikbot, []},
      env: []
    ]
  end

  defp deps do
    [
      {:httpotion, "~> 1.0"},
      {:hedwig, github: "scrogson/hedwig"}
    ]
  end
end
