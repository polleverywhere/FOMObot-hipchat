defmodule Fomobot.Task do
  require Logger
  # TODO: move attributes to config
  @density_threshold 5
  @history_size 10

  def process_message(message) do
    if message.body == "" do
      Logger.debug("Ignoring empty message.")
    else
      Task.Supervisor.async(:task_supervisor, fn ->
        do_process_message(message.body, message.from.resource, message.from.user)
      end)
    end
  end

  def do_process_message(body, from_user, room) do
    Logger.debug("Received message from #{from_user} in #{room} room: #{body}")
    # reply = "Yo, this is JT! I let you know if there are more than #{@density_threshold} messages per minute."
    # {:send_reply, message, reply}
  end
end
