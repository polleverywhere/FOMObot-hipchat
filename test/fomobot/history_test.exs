defmodule Fomobot.History.Test do
  use ExUnit.Case, async: true
  doctest Fomobot.History
  alias Fomobot.History

  def message(user, body) do
    %{from: %{resource: user}, body: body}
  end

  test "add_message" do
    {{false, room_history}, history} =
      History.new
      |> History.add_message("room1", message("bob", "hello"))

    assert History.size(history, "room1") == 1
    {:value, entry} = room_history |> EQueue.head
    assert entry.from_user == "bob"
    assert entry.body == "hello"
  end
end
