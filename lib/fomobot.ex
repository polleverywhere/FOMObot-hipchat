defmodule Fomobot do
  use Application

  def start(_type, args) do
    Fomobot.Supervisor.start_link(args)
  end
end
