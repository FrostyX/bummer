// https://docs.buttplug.io/docs/spec/
// https://docs.intiface.com/docs/intiface-central/hardware/bluetooth/#what-type-of-bluetooth-dongle-should-i-use

import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Pid, sleep}
import gleam/float
import gleam/int
import gleam/io
import websocket

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

pub fn connect(url: String) -> Result(Pid, Dynamic) {
  case websocket.open(url) {
    Ok(socket) -> {
      RequestServerInfo(1, "Test Client")
      |> create_message
      |> websocket.push(socket, _)

      // TODO
      Ok(socket)
    }
    // TODO
    Error(error) -> Error(error)
  }
}

pub fn scan(socket: Pid) -> Pid {
  RequestDeviceList(2)
  |> create_message
  |> websocket.push(socket, _)

  sleep(2000)

  StartScanning(3)
  |> create_message
  |> websocket.push(socket, _)

  sleep(10_000)

  StopScanning(6)
  |> create_message
  |> websocket.push(socket, _)

  socket
}

pub fn vibrate(socket, miliseconds: Int) {
  Vibrate(4, 0, 0.5)
  |> create_message
  |> websocket.push(socket, _)

  sleep(miliseconds)

  Stop(5)
  |> create_message
  |> websocket.push(socket, _)
}

fn sos(socket) {
  // See https://www.codebug.org.uk/learn/step/541/morse-code-timing-rules/
  // The length of a dot is 1 time unit.
  // A dash is 3 time units.
  // The space between symbols (dots and dashes) of the same letter is 1 time unit.
  // The space between letters is 3 time units.
  // The space between words is 7 time units.

  let interval = 200

  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)

  sleep(interval * 3)

  vibrate(socket, interval * 3)
  sleep(interval)
  vibrate(socket, interval * 3)
  sleep(interval)
  vibrate(socket, interval * 3)

  sleep(interval * 3)

  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)
  sleep(interval)
  vibrate(socket, interval)
  // sleep(interval * 7)
}

pub fn main() {
  let url = "ws://127.0.0.1:12345/"
  case connect(url) {
    Ok(socket) -> {
      sos(socket)
      io.println("Done with the socket")
    }
    Error(_) -> {
      io.println("Cannot connect to intiface-engine websocket. Is it running?")
    }
  }
}
