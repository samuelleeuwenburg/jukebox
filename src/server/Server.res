@bs.val external __dirname: string = ""

module Http = {
  type t
  @bs.module("http") external createServer: Express.App.t => t = "createServer"
  @bs.send external listen: (t, int, unit => unit) => unit = ""
}

module IO = {
  type t
  type socket
  type options = Js.Json.t
  @bs.module external io: (Http.t, options) => t = "socket.io"
  @bs.send external on: (t, string, socket => unit) => unit = "on"
  @bs.send external emit: (t, string, 'a) => unit = "emit"

  module Socket = {
    @bs.send external on: (socket, string, Js.Json.t => unit) => unit = "on"
    @bs.send external emit: (socket, string, 'a) => unit = "emit"
  }
}

module Path = {
  type pathT
  @bs.module("path") @bs.splice
  external join: array<string> => string = ""
}

module State = {
  type state = {
    tracks: list<Bragi.track>,
    currentTrack: option<Bragi.currentTrack>,
  }

  type action =
    | PlayTrack(Bragi.track)
    | AddTrack(Bragi.track)
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

  let sortQueue = (tracks: list<Bragi.track>) => {
    open List
    tracks |> sort((a: Bragi.track, b: Bragi.track) =>
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
    | AddTrack(track) => {
        ...state,
        tracks: list{track, ...state.tracks} |> sortQueue,
      }
    | RemoveTrack(trackId) => {
        ...state,
        tracks: state.tracks |> List.filter((track: Bragi.track) => track.id != trackId),
      }
    | VoteOnTrack(trackId, userId) => {
        ...state,
        tracks: state.tracks |> List.map((track: Bragi.track) =>
          if track.id == trackId && track.upvotes->Belt.List.has(userId, \"<>") {
            {
              ...track,
              upvotes: list{userId, ...track.upvotes},
            }
          } else {
            track
          }
        ) |> sortQueue,
      }
    }

  let initialState = {tracks: list{}, currentTrack: None}
}

let (getState, dispatch) = State.init(State.update, State.initialState)
let app = Express.express()
let http = Http.createServer(app)
let io = IO.io(http, Json.Encode.object_(list{("path", Json.Encode.string("/socket.io"))}))

IO.on(io, "connect", socket => {
  Js.log("connection received")

  IO.Socket.on(socket, "vote", json => {
    let trackId = json |> {
      open Json.Decode
      field("trackId", string)
    }
    let userId = json |> {
      open Json.Decode
      field("userId", string)
    }
    Js.log3("received vote", trackId, userId)

    dispatch(VoteOnTrack(trackId, userId)) |> ignore

    let state = getState()

    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> list(Bragi.Encode.track)),
        ("currentTrack", nullable(Bragi.Encode.currentTrack, state.currentTrack)),
      })
    }

    IO.emit(io, "newQueue", json)
  })

  IO.Socket.on(socket, "addTrack", json => {
    let track = json |> Bragi.Decode.track
    let track = {
      ...track,
      timestamp: Js.Date.now(),
      upvotes: list{track.userId},
    }
    dispatch(AddTrack(track)) |> ignore

    let state = getState()

    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> list(Bragi.Encode.track)),
        ("currentTrack", nullable(Bragi.Encode.currentTrack, state.currentTrack)),
      })
    }

    Js.log2("adding track ->", track |> Bragi.Encode.track)
    IO.emit(io, "newQueue", json)
  })

  IO.Socket.on(socket, "getQueue", _ => {
    Js.log("get queue")

    let state = getState()
    let json = {
      open Json.Encode
      object_(list{
        ("tracks", state.tracks |> list(Bragi.Encode.track)),
        ("currentTrack", nullable(Bragi.Encode.currentTrack, state.currentTrack)),
      })
    }

    IO.Socket.emit(socket, "newQueue", json)
  })
})

\"@@"(
  Express.App.useOnPath(app, ~path="/"),
  {
    let publicFolder = Path.join([__dirname, "../../public"])
    let options = Express.Static.defaultOptions()
    Express.Static.make(publicFolder, options) |> Express.Static.asMiddleware
  },
)

Http.listen(http, 3000, () => {
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
            ("tracks", state.tracks |> list(Bragi.Encode.track)),
            ("currentTrack", nullable(Bragi.Encode.currentTrack, state.currentTrack)),
          })
        }

        Js.log2("NOW PLAYING ->", track |> Bragi.Encode.track)
        IO.emit(io, "newQueue", json)
      } else {
        Js.log("no tracks in queue, waiting...")
      }
    | _ => ()
    }
  }, 2000) |> ignore

  Js.log("jukeboxing on port 3000!")
})
