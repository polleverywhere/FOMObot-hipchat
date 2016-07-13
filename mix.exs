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
        :hedwig
      ],
      mod: {Ikbot, []},
      env: []
    ]
  end

  defp deps do
    [
      {:hedwig, github: "scrogson/hedwig"}
    ]
  end
end
