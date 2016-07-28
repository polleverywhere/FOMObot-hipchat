defmodule Fomobot.Processor do
  require Logger
  alias Fomobot.History

  def async(func) do
    Task.Supervisor.async(:processor_supervisor, func)
  end

  def ignore_users, do: Application.get_env(:fomobot, :ignore_users, [])

  # ignore empty message
  def process_message(%{body: ""}), do: nil

  # ignore non-groupchat messages (like presence)
  def process_message(%{type: nil}), do: nil

  @dmsg_handle "@" <> List.first(Application.get_env(:hedwig, :clients)).nickname
  def process_message(message = %{body: @dmsg_handle <> " " <> text}) do
    async fn ->
      process_command(text |> String.trim |> parse_command, message)
    end
  end

  def process_message(message) do
    unless filter_message?(message) do
      start_process_message(message)
    end
  end

  defp filter_message?(%{from: %{resource: resource}}) do
    resource in ignore_users
  end

  defp process_command("revision", message) do
    {:send_reply, message, "FOMObot running revision #{inspect System.get_env("REVISION")}"}
  end

  defp process_command(cmd, message) do
    {:send_reply, message, "Unknown command: #{inspect cmd}"}
  end

  # TODO?
  def parse_command(cmd), do: cmd

  defp start_process_message(message) do
    async fn ->
      do_process_message(message)
    end
  end

  defp do_process_message(message) do
    room = message.from.user

    { is_fomo_event, room_history } = History.add_message(room, message)

    if is_fomo_event do
      {:send_reply, message, notification_message(room, room_history) }
    end
  end

  defp notification_message(room_id, room_history) do
    "@here There's a party in #{room_description(room_id)}! "
    <> "I think they're talking about "
    <> subject_guess(room_history)
    <> "."
  end

  # skip the boring ones
  @ignored_categories [
    "Hobbies & Interests"
  ]

  # TODO: skip if Aylien credentials not entered in config
  defp subject_guess(room_history) do
    response = HTTPotion.post "https://api.aylien.com/api/v1/classify/iab-qag", [
      body: "text=" <> URI.encode_www_form(squashed_room_history(room_history)),
      headers: [
        "X-AYLIEN-TextAPI-Application-Key": Application.get_env(:fomobot, :aylien)[:app_key],
        "X-AYLIEN-TextAPI-Application-ID": Application.get_env(:fomobot, :aylien)[:app_id],
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json"
      ]
    ]

    Poison.decode!(response.body)["categories"]
    |> Enum.map(&(&1["label"]))
    |> Enum.find(&(not &1 in @ignored_categories))
    |> String.downcase
  end

  # TODO: Fetch room description from HipChat server
  defp room_description(room_id) do
    Application.get_env(:fomobot, :room_descriptions)[String.to_atom(room_id)] ||
      String.capitalize(Regex.replace(~r/\A\d+_/, room_id, ""))
  end

  defp squashed_room_history(room_history) do
    room_history
    |> Enum.map(&(&1.body))
    |> Enum.join(" ")
  end
end
