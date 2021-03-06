defmodule Fomobot.History do
  defmodule Entry do
    defstruct [:time, :from_user, :body]

    @doc """
    Creates a new Fomobot.History.Entry from a given message.
    """
    def new(message) do
      %Fomobot.History.Entry{
        time: :erlang.monotonic_time(),
        from_user: message.from.resource,
        body: message.body
      }
    end
  end

  defstruct entries: %{},
            last_notified: %{},
            size: 10

  alias Fomobot.History

  def default_history_size, do: Application.get_env(:fomobot, :history_size)

  @agent __MODULE__

  def start_link do
    Agent.start_link(fn -> Fomobot.History.new end, name: @agent)
  end

  @doc """
  Returns the current History Agent's state.

  ## Example
    iex> Fomobot.History.get
    %Fomobot.History{size: Fomobot.History.default_history_size}
  """
  def get do
    Agent.get(@agent, &(&1))
  end

  @doc """
  Returns a new History instance.

  ## Example
      iex> Fomobot.History.new(10)
      %Fomobot.History{size: 10}

      iex> Fomobot.History.new
      %Fomobot.History{
        size: Fomobot.History.default_history_size
      }
  """
  def new(size \\ default_history_size) do
    %History{
      size: size
    }
  end


  @doc """
  Returns a new History instance with the given entries set.

  ## Example
      iex> Fomobot.History.with_entries(%{"a" => [1,2], "b" => [3,4]})
      %Fomobot.History{
        size: Fomobot.History.default_history_size,
        entries: %{
          "a" => EQueue.from_list([1,2]),
          "b" => EQueue.from_list([3,4])
        }
      }
  """
  def with_entries(entries) when is_map(entries) do
    with_entries(default_history_size, entries)
  end

  @doc """
  Returns a new History instance with the given entries set.

  ## Example
      iex> Fomobot.History.with_entries(10, %{"a" => [1,2], "b" => [3,4]})
      %Fomobot.History{
        size: 10,
        entries: %{
          "a" => EQueue.from_list([1,2]),
          "b" => EQueue.from_list([3,4])
        }
      }
  """
  def with_entries(size, entries) when is_map(entries) do
    queue_entries =
      entries
      |> Enum.map(fn {room, room_entries} ->
        {room, EQueue.from_list(room_entries)}
      end)
      |> Enum.into(%{})

    %History{
      size: size,
      entries: queue_entries
    }
  end

  @doc """
  Adds a message to the running History agent.
  Returns `{is_fomo_event?, room_history}`.
  """
  def add_message(room, message) do
    Agent.get_and_update(@agent, &add_message(&1, room, message))
  end

  def add_message(history = %History{}, room, message) do
    {is_fomo_event, history} =
      history
      |> trim_size(room)
      |> enqueue(room, message)
      |> handle_fomo_event(room)

    room_history = history |> entries(room)

    {{is_fomo_event, room_history}, history}
  end

  def entries(history, room) do
    history.entries[room] || EQueue.new
  end

  def size(history, room) do
     history
     |> entries(room)
     |> EQueue.length
  end

  def trim_size(history, room) do
    room_history = history |> entries(room)

    if (room_history |> EQueue.length) >= history.size do
      {{:value, _dropped_item}, room_history_resized} = EQueue.pop(room_history)
      put_in history.entries[room], room_history_resized
    else
      put_in history.entries[room], room_history
    end
  end

  def enqueue(history, room, message) do
    history
    |> push_entry(room, message)
  end

  defp push_entry(history, room, message) do
    put_in history.entries[room],
           history |> entries(room) |> EQueue.push(History.Entry.new(message))
  end

  defp handle_fomo_event(history, room) do
    if history |> fomo_event?(room) do
      history = put_in history.last_notified[room],
                :erlang.monotonic_time
      {true, history}
    else
      {false, history}
    end
  end

  defp fomo_event?(history, room) do
    history |> exceeds_user_threshold?(room) and
    history |> exceeds_density_threshold?(room) and
    not recently_notified?(history.last_notified[room])
  end

  defp exceeds_user_threshold?(history, room) do
    history |> uniq_user_count(room) >= Application.get_env(:fomobot, :user_threshold)
  end

  defp uniq_user_count(history, room) do
    history
    |> entries(room)
    |> Enum.map(&(&1.from_user))
    |> Enum.uniq
    |> length
  end

  defp exceeds_density_threshold?(history, room) do
    history |> density(room) >= Application.get_env(:fomobot, :density_threshold)
  end

  defp density(history, room) do
    if history |> size(room) < history.size do
      0
    else
      60 * history.size / (history |> secs_elapsed(room) |> max(1))
    end
  end

  defp secs_elapsed(history, room) do
    earliest_time = first_entry(history, room).time
    latest_time   = last_entry(history, room).time
    System.convert_time_unit(latest_time - earliest_time, :native, :seconds)
  end

  defp recently_notified?(nil) do
    false
  end

  defp recently_notified?(last_notified) do
    elapsed_mins = System.convert_time_unit(:erlang.monotonic_time - last_notified, :native, :seconds) / 60
    elapsed_mins < Application.get_env(:fomobot, :debounce_mins)
  end

  defp first_entry(history, room) do
    case history |> entries(room) |> EQueue.head do
      {:value, head}     -> head
      {:empty, _history} -> nil
    end
  end

  defp last_entry(history, room) do
    case history |> entries(room) |> EQueue.last do
      {:value, head}     -> head
      {:empty, _history} -> nil
    end
  end
end
