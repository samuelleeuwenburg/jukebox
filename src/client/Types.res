type track = {
  id: string,
  name: string,
  artist: string,
  uri: string,
  userId: string,
  imageUrl: string,
  durationMs: int,
  upvotes: list<string>,
  timestamp: float,
}

type currentTrack = {
  track: track,
  position: float,
  timestamp: float,
}

type now = {
  tracks: option<list<track>>,
  currentTrack: option<currentTrack>,
}

module Encode = {
  open Json

  let track = (track: track) => {
    Encode.object_(list{
      ("id", Encode.string(track.id)),
      ("name", Encode.string(track.name)),
      ("artist", Encode.string(track.artist)),
      ("uri", Encode.string(track.uri)),
      ("userId", Encode.string(track.userId)),
      ("durationMs", Encode.int(track.durationMs)),
      ("imageUrl", Encode.string(track.imageUrl)),
      ("upvotes", track.upvotes |> Encode.list(Encode.string)),
      ("timestamp", Encode.float(track.timestamp)),
    })
  }

  let currentTrack = (currentTrack: currentTrack) => {
    Encode.object_(list{
      ("track", track(currentTrack.track)),
      ("position", Encode.float(currentTrack.position)),
      ("timestamp", Encode.float(currentTrack.timestamp)),
    })
  }
}

module Decode = {
  open Json

  let track = json => {
    {
      id: json |> Decode.field("id", Decode.string),
      name: json |> Decode.field("name", Decode.string),
      artist: json |> Decode.field("artist", Decode.string),
      uri: json |> Decode.field("uri", Decode.string),
      userId: json |> Decode.field("userId", Decode.string),
      durationMs: json |> Decode.field("durationMs", Decode.int),
      imageUrl: json |> Decode.field("imageUrl", Decode.string),
      upvotes: json |> Decode.withDefault(
        list{},
        Decode.field("upvotes", Decode.list(Decode.string)),
      ),
      timestamp: json |> Decode.withDefault(0.0, Decode.field("timestamp", Decode.float)),
    }
  }

  let currentTrack = json => {
    {
      track: json |> Decode.field("track", track),
      position: json |> Decode.field("position", Decode.float),
      timestamp: json |> Decode.field("timestamp", Decode.float),
    }
  }

  let now = json => {
    {
      tracks: json |> Decode.field("tracks", Decode.optional(Decode.list(track))),
      currentTrack: json |> Decode.field("currentTrack", Decode.optional(currentTrack)),
    }
  }
}

type state = {
  token: option<string>,
  query: string,
  results: option<Spotify.response<Spotify.track>>,
  player: option<Spotify.player>,
  user: option<Spotify.user>,
  queue: option<list<track>>,
  currentTrack: option<currentTrack>,
  userList: option<array<(string, string)>>,
}

type action =
  | NoOp
  | Tick
  | UpdateQuery(string)
  | UpdateResults(Spotify.response<Spotify.track>)
  | UpdatePlayer(Spotify.player)
  | UpdateUser(Spotify.user)
  | UpdateQueue(list<track>)
  | UpdateCurrentTrack(currentTrack)
  | UpdateToken(option<string>)
  | UpdateUserList(array<(string, string)>)
  | HandleNow(now)
  | ClearSearch
  | Error
