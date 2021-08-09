type conn = {id: string}

type socket = {conn: conn}

@send external on: (socket, string, 'a => unit) => unit = "on"
@send external on2: (socket, string, ('a, 'b) => unit) => unit = "on"
@send external on3: (socket, string, ('a, 'b, 'c) => unit) => unit = "on"

@send external off: (socket, string, 'a) => unit = "off"

@send external emit: (socket, string, 'a) => unit = "emit"
@send external emit2: (socket, string, 'a, 'b) => unit = "emit"
@send external emit3: (socket, string, 'a, 'b, 'c) => unit = "emit"

module Server = {
  type server

  @module("socket.io") @new external server: Http.t => server = "Server"
  @send external on: (server, string, socket => unit) => unit = "on"
  @send external emit: (server, string, 'a) => unit = "emit"
}

module Client = {
  @val external io: unit => socket = "io"
}
