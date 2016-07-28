defmodule Fomobot.Supervisor do
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Fomobot.History, [], restart: :permanent),
      supervisor(Task.Supervisor, [[name: :processor_supervisor]])
    ]
    supervise children, strategy: :one_for_one
  end
end
