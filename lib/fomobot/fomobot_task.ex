defmodule Fomobot.Task do
  require Logger

  def process_message(message) do
    Task.Supervisor.async(:task_supervisor, fn ->
      do_process_message(message)
    end)
  end

  defp do_process_message(%{body: ""}) do
    # ignore empty message
  end

  defp do_process_message(message) do
    room = message.from.user

    is_fomo_event = Agent.get_and_update(:room_histories, fn(room_histories) ->
      room_data = room_histories[room] || %{}
      room_history = room_data[:history] || :queue.new
      if :queue.len(room_history) >= Application.get_env(:fomobot, :history_size) do
        {_dropped_item, room_history} = :queue.out(room_history)
      end
      new_room_history = :queue.in(history_entry(message), room_history)

      last_notified = room_data[:last_notified]
      is_fomo_event = fomo_event?(new_room_history, last_notified)

      new_last_notified = if is_fomo_event do
        :erlang.monotonic_time()
      else
        last_notified
      end

      new_room_histories = Map.put(room_histories, room, %{
        history: new_room_history,
        last_notified: new_last_notified
      })

      { is_fomo_event, new_room_histories }
    end)

    if is_fomo_event do
      {:send_reply, message, "@here Yo, there's a party in #{room}!"}
    end
  end

  defp history_entry(message) do
    %{
      time: :erlang.monotonic_time(),
      from_user: message.from.resource,
      body: message.body
    }
  end

  defp fomo_event?(room_history, last_notified) do
    exceeds_user_threshold?(room_history) and
      exceeds_density_threshold?(room_history) and
      not recently_notified?(last_notified)
  end

  defp exceeds_user_threshold?(room_history) do
    uniq_user_count(room_history) >= Application.get_env(:fomobot, :user_threshold)
  end

  defp uniq_user_count(room_history) do
    length(Enum.uniq(Enum.map(:queue.to_list(room_history), &(&1[:from_user]))))
  end

  defp exceeds_density_threshold?(room_history) do
    density(room_history) >= Application.get_env(:fomobot, :density_threshold)
  end

  defp density(room_history) do
    if :queue.len(room_history) < Application.get_env(:fomobot, :history_size) do
      0
    else
      60 * Application.get_env(:fomobot, :history_size) / secs_elapsed(room_history)
    end
  end

  defp secs_elapsed(room_history) do
    earliest_time = :queue.head(room_history)[:time]
    latest_time = :queue.last(room_history)[:time]
    System.convert_time_unit(latest_time - earliest_time, :native, :seconds)
  end

  defp recently_notified?(nil) do
    false
  end

  defp recently_notified?(last_notified) do
    elapsed_mins = System.convert_time_unit(:erlang.monotonic_time() - last_notified, :native, :seconds) / 60
    elapsed_mins < Application.get_env(:fomobot, :debounce_mins)
  end
end
