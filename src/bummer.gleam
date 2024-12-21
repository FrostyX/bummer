// https://docs.buttplug.io/docs/spec/
// https://docs.intiface.com/docs/intiface-central/hardware/bluetooth/#what-type-of-bluetooth-dongle-should-i-use

import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}
import gleam/erlang/process.{type Pid, sleep}
import gleam/float
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
  Vibrate(id: Int, device: Int, speed: Float)
  Stop(id: Int)
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
      "[{\"RequestDeviceList\": {\"Id\": " <> int.to_string(id) <> "}}]"

    StartScanning(id) ->
      "[{\"StartScanning\": {\"Id\": " <> int.to_string(id) <> "}}]"

    StopScanning(id) ->
      "[{\"StopScanning\": {\"Id\": " <> int.to_string(id) <> "}}]"

    Vibrate(id, device, speed) ->
      "[{\"VibrateCmd\": {\"DeviceIndex\": "
      <> int.to_string(device)
      <> ", \"Speeds\": [{\"Index\": 0, \"Speed\": "
      <> float.to_string(speed)
      <> "}], \"Id\": "
      <> int.to_string(id)
      <> "}}]"

    Stop(id) ->
      "[{\"StopDeviceCmd\": {\"DeviceIndex\": 0, \"Id\": "
      <> int.to_string(id)
      <> "}}]"
  }
}

fn vibrate(socket, miliseconds: Int) {
  Vibrate(4, 0, 0.5)
  |> create_message
  |> websocket_echo(socket, _)

  sleep(miliseconds)

  Stop(5)
  |> create_message
  |> websocket_echo(socket, _)
}

fn sos(socket) {
  let interval = 200

  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)

  sleep(interval)

  vibrate(socket, interval * 2)
  sleep(interval)
  vibrate(socket, interval * 2)
  sleep(interval)
  vibrate(socket, interval * 2)

  sleep(interval)

  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)
}

pub fn main() {
  io.println("Hello from bummer!")

  let url = "ws://127.0.0.1:12345/"

  case websocket_open(url) {
    Ok(socket) -> {
      RequestServerInfo(1, "Test Client")
      |> create_message
      |> websocket_echo(socket, _)

      sleep(3500)

      RequestDeviceList(2)
      |> create_message
      |> websocket_echo(socket, _)

      sleep(3500)

      StartScanning(3)
      |> create_message
      |> websocket_echo(socket, _)

      sleep(3500)

      sos(socket)

      sleep(3000)

      StopScanning(6)
      |> create_message
      |> websocket_echo(socket, _)

      io.println("Done with the socket")
    }
    Error(_) -> {
      io.println("Cannot connect to intiface-engine websocket. Is it running?")
    }
  }

  io.println("END")
  sleep(1500)
}
