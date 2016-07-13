defmodule Fomobot.Task do
  def process_message(message) do
    Task.Supervisor.async(:task_supervisor, fn -> do_process_message(message) end)
  end

  def do_process_message(message) do
    reply = "abc123"
    {:send_reply, message, reply}
  end
end
