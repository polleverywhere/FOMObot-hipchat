defmodule Fomobot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fomobot,
      version: "1.0.0",
      elixir: "~>1.0",
      deps: deps
    ]
  end

  def application do
    [
      applications: [
        :hedwig,
        :httpotion
      ],
      mod: {Fomobot, []},
      env: []
    ]
  end

  defp deps do
    [
      # TODO: Change from old fork to newer hedwig_xmpp
      {:hedwig, github: "scrogson/hedwig", tag: "v0.1.0"},
      {:httpotion, "~> 3.0.0"},
      {:poison, "~> 2.0"}
    ]
  end
end
