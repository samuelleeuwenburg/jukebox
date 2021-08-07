@val external __dirname: string = "__dirname"

module Path = {
  @module("path") external resolve: (string, string) => string = "resolve"
  @module("path") @variadic external join: array<string> => string = "join"
}

module State = {
  type state = {
    tracks: array<Types.track>,
    currentTrack: option<Types.currentTrack>,
    users: array<Types.user>,
  }

  type action =
    | PlayTrack(Types.track)
    | AddTrack(Types.track)
    | AddUser(Types.user)
    | RemoveUser(Types.user)
    | RemoveTrack(string)
    | VoteOnTrack(string, Types.user)
    | Tick

  type updateFn = (state, action) => state

  let init = (fn: updateFn, initialState: state) => {
    let state = ref(initialState)

    let get = () => state.contents

    let set = (action: action) => {
      state := fn(state.contents, action)
      state
    }

    (get, set)
  }

  let sortQueue = (tracks: array<Types.track>) => {
    tracks->Belt.SortArray.stableSortBy((a: Types.track, b: Types.track) =>
      if a.upvotes->Belt.Array.length == b.upvotes->Belt.Array.length {
        a.timestamp -. b.timestamp |> int_of_float
      } else {
        b.upvotes->Belt.Array.length - a.upvotes->Belt.Array.length
      }
    )
  }

  let update = (state: state, action: action) =>
    switch action {
    | Tick =>
      switch state.currentTrack {
      | Some(currentTrack) =>
        let now = Js.Date.now()
        let songEndsAt = currentTrack.timestamp +. float_of_int(currentTrack.track.track.durationMs)

        if now > songEndsAt {
          {
            ...state,
            currentTrack: None,
          }
        } else {
          {
            ...state,
            currentTrack: Some({
              ...currentTrack,
              position: now -. currentTrack.timestamp,
            }),
          }
        }
      | None => state
      }
    | PlayTrack(track) => {
        ...state,
        currentTrack: Some({
          track: track,
          timestamp: Js.Date.now(),
          position: 0.0,
        }),
      }
    | AddUser(user) => {
        ...state,
        users: if state.users->Belt.Array.some(u => u.id == user.id) {
          state.users
        } else {
          state.users->Belt.Array.concat([user])
        },
      }
    | RemoveUser(user) => {
        ...state,
        users: state.users->Js.Array2.filter(u => u.id == user.id),
      }
    | AddTrack(track) => {
        ...state,
        tracks: if state.tracks->Belt.Array.some(t => t.track.id == track.track.id) {
          state.tracks
        } else {
          state.tracks->Belt.Array.concat([track])->sortQueue
        },
      }
    | RemoveTrack(trackId) => {
        ...state,
        tracks: state.tracks->Js.Array2.filter((track: Types.track) => track.track.id != trackId),
      }
    | VoteOnTrack(trackId, user) => {
        ...state,
        tracks: state.tracks->Belt.Array.map((track: Types.track) =>
          if track.track.id == trackId && track.upvotes->Belt.Array.some(u => u.id == user.id) {
            {
              ...track,
              upvotes: track.upvotes->Belt.Array.concat([user]),
            }
          } else {
            track
          }
        ) |> sortQueue,
      }
    }

  let initialState = {
    tracks: [],
    currentTrack: None,
    users: [],
  }
}

let (getState, dispatch) = State.init(State.update, State.initialState)
let app = Express.express()
let server = Http.createServer(app)
let io = SocketIO.Server.server(server)

io->SocketIO.Server.on("connect", socket => {
  Js.log2("connection ->", socket.conn.id)
  let userRef = ref(None)

  socket->SocketIO.on("disconnect", () => {
    Js.log3("disconnected ->", socket.conn.id, userRef)
    switch userRef.contents {
    | Some(user) => RemoveUser(user)->dispatch->ignore
    | None => ()
    }

    let state = getState()
    io->SocketIO.Server.emit("newUserList", state.users)
  })

  socket->SocketIO.on("addUser", (user: Spotify.user) => {
    let user = user->User.fromSpotifyUser
    userRef := Some(user)
    AddUser(user)->dispatch->ignore
    Js.log2("User joined -> ", user)

    let state = getState()
    io->SocketIO.Server.emit("newUser", user)
    io->SocketIO.Server.emit("newUserList", state.users)
  })

  socket->SocketIO.on("vote", json => {
    let trackId = Json.Decode.field("trackId", Json.Decode.string, json)
    let user = Json.Decode.field("user", Spotify.Decode.user, json)->User.fromSpotifyUser
    Js.log3("Received vote -> ", trackId, user)

    dispatch(VoteOnTrack(trackId, user))->ignore
    let state = getState()

    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> array(Types.Encode.track)),
        ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
      })
    }

    io->SocketIO.Server.emit("newQueue", json)
  })

  socket->SocketIO.on("addTrack", json => {
    let user = Json.Decode.field("user", Spotify.Decode.user, json)->User.fromSpotifyUser
    let track =
      Json.Decode.field("track", Spotify.Decode.track, json)->Types.Track.fromSpotifyTrack(user)

    dispatch(AddTrack(track)) |> ignore

    let state = getState()

    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> array(Types.Encode.track)),
        ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
      })
    }

    Js.log4("Adding track ->", track.track.artists, " - ", track.track.name)
    io->SocketIO.Server.emit("newQueue", json)
  })

  socket->SocketIO.on("getQueue", _ => {
    let state = getState()

    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> array(Types.Encode.track)),
        ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
      })
    }

    socket->SocketIO.emit("newQueue", json)
  })
})

Express.App.useOnPath(
  app,
  ~path="/",
  {
    let options = Express.Static.defaultOptions()
    let path = Path.join([__dirname, "../../public"])
    Express.Static.make(path, options) |> Express.Static.asMiddleware
  },
)

server->Http.listen(3000, () => {
  Js.Global.setInterval(() => dispatch(Tick) |> ignore, 500) |> ignore

  Js.Global.setInterval(() => {
    let state = getState()

    switch state.currentTrack {
    | None =>
      if state.tracks->Belt.Array.length != 0 {
        let track = state.tracks[0]
        dispatch(RemoveTrack(track.track.id)) |> ignore
        dispatch(PlayTrack(track)) |> ignore

        let state = getState()
        let json = {
          open Json.Encode
          object_(list{
            ("tracks", state.tracks |> array(Types.Encode.track)),
            ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
          })
        }

        Js.log4("Now playing ->", track.track.artists, " - ", track.track.name)
        io->SocketIO.Server.emit("newQueue", json)
      }
    | _ => ()
    }
  }, 2000) |> ignore

  Js.log("jukeboxing on port 3000!")
})
