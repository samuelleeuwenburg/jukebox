let baseUrl = "https://api.spotify.com/v1"
let clientId = "4f8a771ca0aa41b28424ad9fc737dacc"
let scopes = "user-modify-playback-state user-read-playback-state user-read-private user-read-email"
let redirectUrl = "http://127.0.0.1:3000"

let authenticate = () => {
  open Utils

  let url =
    "https://accounts.spotify.com/authorize" ++
    ("?response_type=token" ++
    ("&client_id=" ++
    (encodeURIComponent(clientId) ++
    ("&scope=" ++
    (encodeURIComponent(scopes) ++
    ("&redirect_uri=" ++ (encodeURIComponent(redirectUrl) ++ "&state=abcdefg")))))))

  goToUrl(url)
}

type user = {
  id: string,
  displayName: string,
}

type image = {
  url: string,
  height: int,
  width: int,
}

type artist = {name: string}

type album = {
  name: string,
  images: list<image>,
}

type track = {
  id: string,
  uri: string,
  name: string,
  artists: list<artist>,
  album: album,
  durationMs: int,
}

type device = {
  id: string,
  name: string,
}

type player = {
  device: device,
  isPlaying: bool,
  progressMs: int,
}

type response<'a> = {
  items: list<'a>,
  total: int,
}

module Decode = {
  let image = json => {
    open Json.Decode
    {
      url: json |> field("url", string),
      height: json |> field("height", int),
      width: json |> field("width", int),
    }
  }

  let artist = json => {
    open Json.Decode
    {
      name: json |> field("name", string),
    }
  }

  let album = json => {
    open Json.Decode
    {
      name: json |> field("name", string),
      images: json |> field("images", list(image)),
    }
  }

  let track = json => {
    open Json.Decode
    {
      id: json |> field("id", string),
      uri: json |> field("uri", string),
      name: json |> field("name", string),
      artists: json |> field("artists", list(artist)),
      album: json |> field("album", album),
      durationMs: json |> field("duration_ms", int),
    }
  }

  let tracks = json => {
    open Json.Decode
    {
      items: json |> at(list{"tracks", "items"}, list(track)),
      total: json |> at(list{"tracks", "total"}, int),
    }
  }

  let device = json => {
    open Json.Decode
    {
      id: json |> field("id", string),
      name: json |> field("name", string),
    }
  }

  let user = json => {
    open Json.Decode
    {
      id: json |> field("id", string),
      displayName: json |> field("display_name", string),
    }
  }

  let player = json => {
    open Json.Decode
    {
      device: json |> field("device", device),
      isPlaying: json |> field("is_playing", bool),
      progressMs: json |> field("progress_ms", int),
    }
  }
}

let getTracks = (token: string, query: string) => {
  open Utils

  let url = baseUrl ++ ("/search?q=" ++ (encodeURIComponent(query) ++ "&type=track"))

  open Js.Promise
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(
      ~method_=Get,
      ~headers=Fetch.HeadersInit.make({"Authorization": "Bearer " ++ token}),
      (),
    ),
  )
  |> then_(Fetch.Response.json)
  |> then_(json => json |> Decode.tracks |> resolve)
}

let getUser = (token: string) => {
  let url = baseUrl ++ "/me"

  open Js.Promise
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(
      ~method_=Get,
      ~headers=Fetch.HeadersInit.make({"Authorization": "Bearer " ++ token}),
      (),
    ),
  )
  |> then_(Fetch.Response.json)
  |> then_(json => json |> Decode.user |> resolve)
}

let getPlayer = (token: string) => {
  let url = baseUrl ++ "/me/player"

  open Js.Promise
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(
      ~method_=Get,
      ~headers=Fetch.HeadersInit.make({"Authorization": "Bearer " ++ token}),
      (),
    ),
  )
  |> then_(Fetch.Response.json)
  |> then_(json => json |> Decode.player |> resolve)
}

let playTrack = (token: string, songUri: string, positionMs: float) => {
  let url = baseUrl ++ "/me/player/play"
  let payload = Js.Dict.empty()

  Js.Dict.set(payload, "uris", Js.Json.array([Js.Json.string(songUri)]))

  if positionMs != 0.0 {
    Js.Dict.set(payload, "position_ms", Js.Json.number(positionMs))
  }

  open Js.Promise
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(
      ~method_=Put,
      ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(payload))),
      ~headers=Fetch.HeadersInit.make({
        "Authorization": "Bearer " ++ token,
        "Content-Type": "application/json",
        "Accept": "application/json",
      }),
      (),
    ),
  ) |> then_(Fetch.Response.json)
  //@TODO: return something back to the application?
}
