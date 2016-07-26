defmodule Fomobot.Supervisor do
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      supervisor(Task.Supervisor, [[name: :task_supervisor]])
    ]
    Agent.start_link(fn -> Map.new end, name: :room_histories)
    supervise children, strategy: :one_for_one
  end
end
