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

  def process_message(message) do
    unless filter_message?(message) do
      start_process_message(message)
    end
  end

  defp filter_message?(%{from: %{resource: resource}}) do
    resource in ignore_users
  end

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
    [at_mentions, room_sentence(room_id), subject_guess_sentence(room_history)]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  defp at_mentions do
    "@here"
  end

  defp room_sentence(room_id) do
    "There's a party in #{room_description(room_id)}!"
  end

  defp subject_guess_sentence(room_history) do
    subject_guess_to_sentence(subject_guess(room_history))
  end

  defp subject_guess_to_sentence("") do
    ""
  end

  defp subject_guess_to_sentence(subject_guess) do
    "I think they're talking about #{subject_guess}."
  end

  defp subject_guess(room_history) do
    if not contextual_analysis_enabled? do
      ""
    else
      room_history
      |> potential_subject_categories
      |> Enum.map(&(&1["label"]))
      |> Enum.find(&(not &1 in ignored_categories))
      |> to_string
      |> String.downcase
    end
  end

  defp contextual_analysis_enabled? do
    Application.get_env(:fomobot, :contextual_analysis, %{}) != %{}
  end

  defp potential_subject_categories(room_history) do
    response = HTTPotion.post(
      "https://api.aylien.com/api/v1/classify/iab-qag",
      body: "text=" <> URI.encode_www_form(squashed_room_history(room_history)),
      headers: [
        "X-AYLIEN-TextAPI-Application-Key": Application.get_env(:fomobot, :contextual_analysis)[:aylien_login][:app_key],
        "X-AYLIEN-TextAPI-Application-ID": Application.get_env(:fomobot, :contextual_analysis)[:aylien_login][:app_id],
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json"
      ]
    )

    Poison.decode!(response.body)["categories"]
  end

  defp ignored_categories do
    Application.get_env(:fomobot, :contextual_analysis)[:ignored_categories] || []
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
