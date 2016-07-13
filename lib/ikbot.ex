defmodule Ikbot do
  use Application

  def start(_type, args) do
    Ikbot.Supervisor.start_link(args)
  end
end
