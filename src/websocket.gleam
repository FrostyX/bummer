import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}
import gleam/erlang/process.{type Pid}

@external(erlang, "Elixir.Socket", "set_log_level")
pub fn set_log_level(level: Atom) -> Nil

@external(erlang, "Elixir.Socket", "start_link")
pub fn open(url: String) -> Result(Pid, Dynamic)

@external(erlang, "Elixir.Socket", "echo")
pub fn push(client: Pid, message: String) -> Atom
