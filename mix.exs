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
        :hedwig
      ],
      mod: {Fomobot, []},
      env: []
    ]
  end

  defp deps do
    [
      {:hedwig, github: "scrogson/hedwig"}
    ]
  end
end
