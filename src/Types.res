type user = {
  id: string,
  color: string,
}

type track = {
  track: Spotify.track,
  user: user,
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

module Log = {
  type message =
    | UserJoined(user)
    | UserLeft(user)
    | TrackAdded(track, user)
    | TrackVoted(track, user)

  type t = {
    message: message,
    timestamp: float,
  }

  let make = message => {
    {message: message, timestamp: Js.Date.now()}
  }
}

module Encode = {
  open Json

  let user = (user: user) => {
    Encode.object_(list{("id", Encode.string(user.id)), ("color", Encode.string(user.color))})
  }

  let track = (track: track) => {
    Encode.object_(list{
      ("track", Spotify.Encode.track(track.track)),
      ("user", user(track.user)),
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
      track: json |> Decode.field("track", Spotify.Decode.track),
      user: json |> Decode.field("user", user),
      upvotes: json |> Decode.withDefault([], Decode.field("upvotes", Decode.array(user))),
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

module Track = {
  let fromSpotifyTrack = (track: Spotify.track, user: user) => {
    {
      track: track,
      user: user,
      timestamp: Js.Date.now(),
      upvotes: [user],
    }
  }
}

module Socket = {
  type t =
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
}
