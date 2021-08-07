@val external __dirname: string = "__dirname"

module Path = {
  @module("path") external resolve: (string, string) => string = "resolve"
  @module("path") @variadic external join: array<string> => string = "join"
}

module State = {
  type state = {
    tracks: list<Types.track>,
    currentTrack: option<Types.currentTrack>,
    users: Belt.Set.String.t,
  }

  type action =
    | PlayTrack(Types.track)
    | AddTrack(Types.track)
    | AddUser(string)
    | RemoveTrack(string)
    | VoteOnTrack(string, string)
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

  let sortQueue = (tracks: list<Types.track>) => {
    open List
    tracks |> sort((a: Types.track, b: Types.track) =>
      if a.upvotes->length == b.upvotes->length {
        a.timestamp -. b.timestamp |> int_of_float
      } else {
        b.upvotes->length - a.upvotes->length
      }
    )
  }

  let update = (state: state, action: action) =>
    switch action {
    | Tick =>
      switch state.currentTrack {
      | Some(currentTrack) =>
        let now = Js.Date.now()
        let songEndsAt = currentTrack.timestamp +. float_of_int(currentTrack.track.durationMs)

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
        users: state.users->Belt.Set.String.add(user),
      }
    | AddTrack(track) => {
        ...state,
        tracks: list{track, ...state.tracks} |> sortQueue,
      }
    | RemoveTrack(trackId) => {
        ...state,
        tracks: state.tracks |> List.filter((track: Types.track) => track.id != trackId),
      }
    | VoteOnTrack(trackId, user) => {
        ...state,
        tracks: state.tracks
        |> List.map((track: Types.track) =>
          if track.id == trackId && track.upvotes->Belt.List.has(user, (a, b) => a == b) {
            {
              ...track,
              upvotes: list{user, ...track.upvotes},
            }
          } else {
            track
          }
        )
        |> sortQueue,
      }
    }

  let initialState = {
    tracks: list{},
    currentTrack: None,
    users: Belt.Set.String.empty,
  }
}

let (getState, dispatch) = State.init(State.update, State.initialState)
let app = Express.express()
let server = Http.createServer(app)
let io = SocketIO.Server.server(server)

io->SocketIO.Server.on("connect", socket => {
  Js.log("connection received")

  socket->SocketIO.on("addUser", (user: Spotify.user) => {
    Js.log2("user joined: ", user.displayName)

    AddUser(user.displayName)->dispatch->ignore
    let state = getState()
    let userList = state.users->Belt.Set.String.toArray->Belt.Array.map(User.hash)

    io->SocketIO.Server.emit("newUserList", userList)
  })

  socket->SocketIO.on("vote", json => {
    let trackId = Json.Decode.field("trackId", Json.Decode.string, json)
    let user = json->Spotify.Decode.user
    Js.log3("received vote", trackId, user)

    let (user, _) = user.displayName->User.hash
    dispatch(VoteOnTrack(trackId, user))->ignore

    let state = getState()

    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> list(Types.Encode.track)),
        ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
      })
    }

    io->SocketIO.Server.emit("newQueue", json)
  })

  socket->SocketIO.on("addTrack", json => {
    let track = json |> Types.Decode.track
    let (user, _) = track.userId->User.hash
    let track = {
      ...track,
      userId: user,
      timestamp: Js.Date.now(),
      upvotes: list{user},
    }
    dispatch(AddTrack(track)) |> ignore

    let state = getState()

    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> list(Types.Encode.track)),
        ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
      })
    }

    Js.log2("adding track ->", track |> Types.Encode.track)
    io->SocketIO.Server.emit("newQueue", json)
  })

  socket->SocketIO.on("getQueue", _ => {
    Js.log("get queue")

    let state = getState()
    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> list(Types.Encode.track)),
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
      if List.length(state.tracks) != 0 {
        let track = List.hd(state.tracks)
        dispatch(RemoveTrack(track.id)) |> ignore
        dispatch(PlayTrack(track)) |> ignore

        let state = getState()
        let json = {
          open Json.Encode
          object_(list{
            ("tracks", state.tracks |> list(Types.Encode.track)),
            ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
          })
        }

        Js.log2("NOW PLAYING ->", track |> Types.Encode.track)
        io->SocketIO.Server.emit("newQueue", json)
      }
    | _ => ()
    }
  }, 2000) |> ignore

  Js.log("jukeboxing on port 3000!")
})
