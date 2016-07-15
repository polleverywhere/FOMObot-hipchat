defmodule Fomobot.Task do
  require Logger
  # TODO: move attributes to config
  @density_threshold 5
  @history_size 10

  def process_message(message) do
    Task.Supervisor.async(:task_supervisor, fn ->
      do_process_message(message)
    end)
  end

  def do_process_message(%{body: ""}) do
    # ignore empty message
  end

  def do_process_message(message) do
    body = message.body
    from_user = message.from.resource
    room = message.from.user
    Logger.debug("Received message from #{from_user} in #{room} room: #{body}")
    if from_user == "Mike Foley" do
      reply = "Mike just said: #{body}"
      {:send_reply, message, reply}
    end
  end
end
