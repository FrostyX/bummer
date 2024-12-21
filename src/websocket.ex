# https://github.com/Azolo/websockex/blob/master/examples/echo_client.exs
defmodule Socket do
  use WebSockex
  require Logger

  def set_log_level(level) do
    Logger.configure(level: level)
  end

  def start_link(url, opts \\ []) do
    WebSockex.start_link(url, __MODULE__, :fake_state, opts)
  end

  def echo(client, message) do
    Logger.debug("Sending message: #{message}")
    WebSockex.send_frame(client, {:text, message})
  end

  def handle_connect(_conn, state) do
    Logger.debug("Connected!")
    {:ok, state}
  end

  def handle_frame({:text, msg}, :fake_state) do
    Logger.debug("Received Message: #{msg}")
    {:ok, :fake_state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.debug("Local close with reason: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end
end
