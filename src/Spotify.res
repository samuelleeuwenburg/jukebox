let baseUrl = "https://api.spotify.com/v1"
let clientId = "4f8a771ca0aa41b28424ad9fc737dacc"
let scopes = "user-modify-playback-state user-read-playback-state"

module Token = {
  type tokenResponse = {
    accessToken: string,
    refreshToken: string,
    expiresIn: int,
  }

  module Decode = {
    open Json.Decode

    let tokenResponse = json => {
      {
        accessToken: json |> field("access_token", string),
        refreshToken: json |> field("refresh_token", string),
        expiresIn: json |> field("expires_in", int),
      }
    }
  }

  let authenticate = () => {
    open Utils

    let url =
      "https://accounts.spotify.com/authorize" ++
      "?response_type=code" ++
      "&client_id=" ++
      encodeURIComponent(clientId) ++
      "&scope=" ++
      encodeURIComponent(scopes) ++
      "&redirect_uri=" ++
      encodeURIComponent(origin) ++ "&state=abcdefg"

    goToUrl(url)
  }

  let getNewAccessToken = (clientSecret, refreshToken) => {
    open Utils
    open Js.Promise

    let payload =
      "grant_type=refresh_token" ++
      "&client_id=" ++
      encodeURIComponent(clientId) ++
      "&client_secret=" ++
      encodeURIComponent(clientSecret) ++
      "&refresh_token=" ++
      refreshToken

    Fetch.fetchWithInit(
      "https://accounts.spotify.com/api/token",
      Fetch.RequestInit.make(
        ~method_=Post,
        ~body=Fetch.BodyInit.make(payload),
        ~headers=Fetch.HeadersInit.make({
          "Content-Type": "application/x-www-form-urlencoded",
        }),
        (),
      ),
    ) |> then_(Fetch.Response.json)
  }

  let get = socket => {
    open Dom.Storage

    let expiresAt =
      getItem("expires_at", localStorage)->Belt.Option.flatMap(s => s->Belt.Float.fromString)

    switch (
      expiresAt,
      getItem("access_token", localStorage),
      getItem("refresh_token", localStorage),
    ) {
    | (Some(expiresAt), Some(accessToken), Some(refreshToken)) => {
        if Js.Date.now() >= expiresAt {
          socket->SocketIO.emit("requestNewAccessToken", refreshToken)
        }

        Some(accessToken)
      }
    | _ => None
    }
  }

  let getRefresh = (clientSecret, clientURI, code) => {
    open Utils
    open Js.Promise

    let payload =
      "grant_type=authorization_code" ++
      "&client_id=" ++
      encodeURIComponent(clientId) ++
      "&client_secret=" ++
      encodeURIComponent(clientSecret) ++
      "&code=" ++
      encodeURIComponent(code) ++
      "&redirect_uri=" ++
      encodeURIComponent(clientURI)

    Fetch.fetchWithInit(
      "https://accounts.spotify.com/api/token",
      Fetch.RequestInit.make(
        ~method_=Post,
        ~body=Fetch.BodyInit.make(payload),
        ~headers=Fetch.HeadersInit.make({
          "Content-Type": "application/x-www-form-urlencoded",
        }),
        (),
      ),
    ) |> then_(Fetch.Response.json)
  }

  let saveRefresh = token => {
    open Dom.Storage
    localStorage |> setItem("refresh_token", token)
  }

  let saveAccess = (token, expiresIn) => {
    open Dom.Storage
    let expireDate = Belt.Int.toFloat(expiresIn) *. 1000.0 +. Js.Date.now()
    localStorage |> setItem("access_token", token)
    localStorage |> setItem("expires_at", expireDate->Belt.Float.toString)
  }

  let clear = () => {
    open Dom.Storage
    localStorage |> removeItem("access_token")
    localStorage |> removeItem("refresh_token")
    localStorage |> removeItem("expires_at")
  }
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
  images: array<image>,
}

type track = {
  id: string,
  uri: string,
  name: string,
  artists: array<artist>,
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
  items: array<'a>,
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
      images: json |> field("images", array(image)),
    }
  }

  let track = json => {
    open Json.Decode
    {
      id: json |> field("id", string),
      uri: json |> field("uri", string),
      name: json |> field("name", string),
      artists: json |> field("artists", array(artist)),
      album: json |> field("album", album),
      durationMs: json |> field("duration_ms", int),
    }
  }

  let tracks = json => {
    open Json.Decode
    {
      items: json |> at(list{"tracks", "items"}, array(track)),
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

module Encode = {
  open Json.Encode

  let artist = (artist: artist) => {
    object_(list{("name", string(artist.name))})
  }

  let image = (image: image) => {
    object_(list{
      ("url", string(image.url)),
      ("height", int(image.height)),
      ("width", int(image.width)),
    })
  }

  let album = (album: album) => {
    object_(list{("name", string(album.name)), ("images", album.images |> array(image))})
  }

  let user = (user: user) => {
    object_(list{("id", string(user.id)), ("display_name", string(user.displayName))})
  }

  let track = (track: track) => {
    object_(list{
      ("id", string(track.id)),
      ("name", string(track.name)),
      ("artists", track.artists |> array(artist)),
      ("uri", string(track.uri)),
      ("album", album(track.album)),
      ("duration_ms", int(track.durationMs)),
    })
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
}

let getDevices = (token: string) => {
  let url = baseUrl ++ "/me/player/devices"

  open Js.Promise
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(
      ~method_=Get,
      ~headers=Fetch.HeadersInit.make({
        "Authorization": "Bearer " ++ token,
        "Content-Type": "application/json",
        "Accept": "application/json",
      }),
      (),
    ),
  ) |> then_(Fetch.Response.json)
}

let transferPlayback = (token: string, deviceId: string) => {
  let url = baseUrl ++ "/me/player"
  let payload = Js.Dict.empty()

  Js.Dict.set(payload, "device_ids", Js.Json.array([Js.Json.string(deviceId)]))

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
  )
}

module Track = {
  let getImage = (track: track) => {
    let sorted =
      track.album.images->Belt.SortArray.stableSortBy((a: image, b: image) => b.width - a.width)

    sorted[0]
  }

  let getArtistName = (track: track) => {
    let first = track.artists[0]
    first.name
  }
}
