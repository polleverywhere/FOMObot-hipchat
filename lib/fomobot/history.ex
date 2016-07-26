defmodule Fomobot.History do
  defmodule Entry do
    defstruct [:time, :from_user, :body]

    def new(message) do
      %Fomobot.History.Entry{
        time: :erlang.monotonic_time(),
        from_user: message.from.resource,
        body: message.body
      }
    end
  end
end
