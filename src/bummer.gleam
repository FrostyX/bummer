import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}
import gleam/erlang/process.{type Pid, sleep}
import gleam/float
import gleam/int
import gleam/io
import gleam/result
import websocket

const message_id = 1

type Message {
  RequestServerInfo(id: Int, client_name: String)
  RequestDeviceList(id: Int)
  StartScanning(id: Int)
  StopScanning(id: Int)
  Vibrate(id: Int, device: Int, speed: Float)
  Rotate(id: Int, device: Int, speed: Float)
  Stop(id: Int)
}

pub type Connection =
  Pid

pub fn set_log_level(level: Atom) -> Nil {
  websocket.set_log_level(level)
}

fn serialize(message: Message) {
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

    Rotate(id, device, speed) ->
      "[{\"RotateCmd\": {\"DeviceIndex\": "
      <> int.to_string(device)
      <> ", \"Rotations\": [{\"Index\": 0, \"Speed\": "
      <> float.to_string(speed)
      <> ", \"Clockwise\": true"
      <> "}], \"Id\": "
      <> int.to_string(id)
      <> "}}]"

    Stop(id) ->
      "[{\"StopDeviceCmd\": {\"DeviceIndex\": 0, \"Id\": "
      <> int.to_string(id)
      <> "}}]"
  }
}

pub fn connect(url: String) -> Result(Connection, Dynamic) {
  use socket <- result.try(websocket.open(url))
  RequestServerInfo(message_id, "Bummer")
  |> serialize
  |> websocket.push(socket, _)
  Ok(socket)
}

pub fn scan(socket: Connection, miliseconds: Int) -> Atom {
  let res =
    StartScanning(message_id)
    |> serialize
    |> websocket.push(socket, _)

  sleep(miliseconds)
  res
}

fn do(socket, message: Message, miliseconds: Int) -> Nil {
  message
  |> serialize
  |> websocket.push(socket, _)

  sleep(miliseconds)

  Stop(message_id)
  |> serialize
  |> websocket.push(socket, _)

  Nil
}

pub fn vibrate(socket, miliseconds: Int) -> Nil {
  let device = 0
  let speed = 0.5
  Vibrate(message_id, device, speed) |> do(socket, _, miliseconds)
}

pub fn rotate(socket, miliseconds: Int) -> Nil {
  let device = 0
  let speed = 0.5
  Rotate(message_id, device, speed) |> do(socket, _, miliseconds)
}

pub fn main() {
  websocket.set_log_level(atom.create_from_string("info"))
  case connect("ws://127.0.0.1:12345/") {
    Ok(socket) -> {
      io.println("Connected to intiface-engine websocket")
      io.println("Initiating a test sequence")

      scan(socket, 5000)
      vibrate(socket, 500)
      sleep(500)
      rotate(socket, 500)

      io.println("Test sequence finished")
    }
    Error(_) ->
      "Cannot connect to intiface-engine websocket. Is it running?"
      |> io.println_error
  }
}
