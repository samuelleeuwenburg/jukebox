type message =
| SendLog
| RequestUser
| SendUser
| SendUserList
| RequestRefreshToken
| SendRefreshToken
| RequestAccessToken
| SendAccessToken
| RequestQueue
| SendQueue
| TrackAdd
| TrackVote

type conn = {id: string}

type socket = {conn: conn}

@send external on: (socket, 't, 'a => unit) => unit = "on"
@send external on2: (socket, 't, (. 'a, 'b) => unit) => unit = "on"
@send external on3: (socket, 't, (. 'a, 'b, 'c) => unit) => unit = "on"

@send external off: (socket, 't, 'a) => unit = "off"

@send external emit: (socket, 't, 'a) => unit = "emit"
@send external emit2: (socket, 't, 'a, 'b) => unit = "emit"
@send external emit3: (socket, 't, 'a, 'b, 'c) => unit = "emit"

module Server = {
  type server

  @module("socket.io") @new external server: Http.t => server = "Server"
  @send external on: (server, 't, socket => unit) => unit = "on"
  @send external emit: (server, 't, 'a) => unit = "emit"
  @send external emit2: (server, 't, 'a, 'b) => unit = "emit"
  @send external emit3: (server, 't, 'a, 'b, 'c) => unit = "emit"
}

module Client = {
  @val external io: unit => socket = "io"
}
