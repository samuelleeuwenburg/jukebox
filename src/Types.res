type user = {
  id: string,
  color: string,
}

type track = {
  id: string,
  name: string,
  artist: string,
  uri: string,
  user: user,
  imageUrl: string,
  durationMs: int,
  upvotes: array<user>,
  timestamp: float,
}

type currentTrack = {
  track: track,
  position: float,
  timestamp: float,
}

type now = {
  tracks: option<array<track>>,
  currentTrack: option<currentTrack>,
}

module Encode = {
  open Json

  let user = (user: user) => {
    Encode.object_(list{
      ("id", Encode.string(user.id)),
      ("color", Encode.string(user.color)),
    })
  }

  let track = (track: track) => {
    Encode.object_(list{
      ("id", Encode.string(track.id)),
      ("name", Encode.string(track.name)),
      ("artist", Encode.string(track.artist)),
      ("uri", Encode.string(track.uri)),
      ("user", user(track.user)),
      ("durationMs", Encode.int(track.durationMs)),
      ("imageUrl", Encode.string(track.imageUrl)),
      ("upvotes", track.upvotes |> Encode.array(user)),
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

  let user = json => {
    {
      id: json |> Decode.field("id", Decode.string),
      color: json |> Decode.field("color", Decode.string),
    }
  }

  let track = json => {
    {
      id: json |> Decode.field("id", Decode.string),
      name: json |> Decode.field("name", Decode.string),
      artist: json |> Decode.field("artist", Decode.string),
      uri: json |> Decode.field("uri", Decode.string),
      user: json |> Decode.field("user", user),
      durationMs: json |> Decode.field("durationMs", Decode.int),
      imageUrl: json |> Decode.field("imageUrl", Decode.string),
      upvotes: json |> Decode.withDefault(
        [],
        Decode.field("upvotes", Decode.array(user)),
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
      tracks: json |> Decode.field("tracks", Decode.optional(Decode.array(track))),
      currentTrack: json |> Decode.field("currentTrack", Decode.optional(currentTrack)),
    }
  }
}

type state = {
  token: option<string>,
  query: string,
  results: option<Spotify.response<Spotify.track>>,
  player: option<Spotify.player>,
  spotifyUser: option<Spotify.user>,
  user: option<user>,
  queue: option<array<track>>,
  currentTrack: option<currentTrack>,
  userList: option<array<(string, string)>>,
}

type action =
  | NoOp
  | Tick
  | UpdateQuery(string)
  | UpdateResults(Spotify.response<Spotify.track>)
  | UpdatePlayer(Spotify.player)
  | UpdateSpotifyUser(Spotify.user)
  | UpdateUser(user)
  | UpdateQueue(array<track>)
  | UpdateCurrentTrack(currentTrack)
  | UpdateToken(option<string>)
  | UpdateUserList(array<(string, string)>)
  | HandleNow(now)
  | ClearSearch
  | Error
