type socket

@send external on: (socket, string, 'a => unit) => unit = "on"
@send external off: (socket, string, 'a => unit) => unit = "off"
@send external emit: (socket, string, 'a) => unit = "emit"

module Server = {
  type server

  @module("socket.io") @new external server: Http.t => server = "Server"
  @send external on: (server, string, socket => unit) => unit = "on"
  @send external emit: (server, string, 'a) => unit = "emit"
}

module Client = {
  @val external io: unit => socket = "io"
}
