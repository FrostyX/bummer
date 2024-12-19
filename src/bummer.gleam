// https://docs.buttplug.io/docs/spec/
// https://docs.intiface.com/docs/intiface-central/hardware/bluetooth/#what-type-of-bluetooth-dongle-should-i-use

import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}
import gleam/erlang/process.{type Pid, sleep}
import gleam/int
import gleam/io

@external(erlang, "Elixir.BummerSocket", "start_link")
fn websocket_open(url: String) -> Result(Pid, Dynamic)

@external(erlang, "Elixir.BummerSocket", "echo")
fn websocket_echo(client: Pid, message: String) -> Atom

type Message {
  RequestServerInfo(id: Int, client_name: String)
  RequestDeviceList(id: Int)
  StartScanning(id: Int)
  StopScanning(id: Int)
}

fn create_message(message: Message) {
  case message {
    // The json module should be easy to use, e.g
    // [#("Id", 1] |> json.object |> json.to_string
    // But I have some issues with Erlang OTP. Neither version of json module
    // works for me.
    RequestServerInfo(id, client_name) ->
      "[{\"RequestServerInfo\": {\"ClientName\": \""
      <> client_name
      <> "\", \"MessageVersion\": 1, \"Id\": "
      <> int.to_string(id)
      <> "}}]"

    RequestDeviceList(id) ->
      "[{\"StartScanning\": {\"Id\": " <> int.to_string(id) <> "}}]"

    StartScanning(id) ->
      "[{\"StartScanning\": {\"Id\": " <> int.to_string(id) <> "}}]"

    StopScanning(id) ->
      "[{\"StopScanning\": {\"Id\": " <> int.to_string(id) <> "}}]"
  }
}

pub fn main() {
  io.println("Hello from bummer!")

  let url = "ws://127.0.0.1:12345/"

  case websocket_open(url) {
    Ok(socket) -> {
      io.debug(socket)

      RequestServerInfo(1, "Test Client")
      |> create_message
      |> websocket_echo(socket, _)
      |> io.debug

      RequestDeviceList(2)
      |> create_message
      |> websocket_echo(socket, _)
      |> io.debug

      StartScanning(3)
      |> create_message
      |> websocket_echo(socket, _)
      |> io.debug

      sleep(60_000)

      StopScanning(4)
      |> create_message
      |> websocket_echo(socket, _)
      |> io.debug

      io.println("Done with the socket")
    }
    Error(_) -> {
      io.println("Cannot connect to intiface-engine websocket. Is it running?")
    }
  }

  io.println("END")
  sleep(1500)
}
