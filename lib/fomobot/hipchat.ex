defmodule Fomobot.Hipchat do
  alias Fomobot.Task
  use Hedwig.Handler

  def init_keepalive do
    Enum.each clients, fn(%{jid: jid}) ->
      %{event_manager: pid} = jid |> String.to_atom |> Process.whereis |> :sys.get_state
      GenEvent.notify(pid, :init_keepalive)
    end
  end

  def handle_event(%Message{} = message, opts) do
    Task.process_message(message)
    {:ok, opts}
  end

  def handle_event(:init_keepalive, opts) do
    :erlang.send_after(keepalive_delay, self, :send_keepalive)
    {:ok, opts}
  end

  def handle_event(_event, opts) do
    {:ok, opts}
  end

  def handle_info({_from, {:send_reply, message, reply}}, opts) do
    # Default behavior is to reply in the same room.
    # This writes to the FOMO room instead.
    message = put_in(message.from.user, notify_room)
    Hedwig.Handler.reply(message, Stanza.body(reply))
    {:ok, opts}
  end

  def handle_info(:send_keepalive, opts) do
    pid = opts.client.jid |> String.to_atom |> Process.whereis
    client = Hedwig.Client.client_for(opts.client.jid)

    stanza = Hedwig.Stanza.join(hd(client.rooms), client.nickname)
    Hedwig.Client.reply(pid, stanza)

    :erlang.send_after(keepalive_delay, self, :send_keepalive)
    {:ok, opts}
  end

  def handle_info(_msg, opts) do
    {:ok, opts}
  end

  # config helpers
  def clients,         do: Application.get_env(:hedwig, :clients)
  def keepalive_delay, do: Application.get_env(:fomobot, :keepalive_delay)
  def notify_room,     do: Application.get_env(:fomobot, :notify_room)
end
