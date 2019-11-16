let baseUrl = "https://api.spotify.com/v1";
let clientId = "4f8a771ca0aa41b28424ad9fc737dacc";
let scopes = "user-modify-playback-state user-read-playback-state user-read-private user-read-email";
let redirectUrl = "http://127.0.0.1:8000";

let authenticate = () => {
    open Utils;

    let url = "https://accounts.spotify.com/authorize"
        ++ "?response_type=token"
        ++ "&client_id=" ++ encodeURIComponent(clientId)
        ++ "&scope=" ++ encodeURIComponent(scopes)
        ++ "&redirect_uri=" ++ encodeURIComponent(redirectUrl)
        ++ "&state=abcdefg";

    goToUrl(url);
};

type user = {
    id: string
};

type image = {
    url: string,
    height: int,
    width: int
}

type artist = {
    name: string,
}

type album = {
    name: string,
    images: list(image),
}

type track = {
    id: string,
    uri: string,
    name: string,
    artists: list(artist),
    album: album,
    durationMs: int,
}

type device = {
    id: string,
    name: string
}

type player = {
    device: device,
    isPlaying: bool,
    progressMs: int
};

type response('a) = {
    items: list('a),
    total: int
}

module Decode = {
    let image = json =>
        Json.Decode.{
            url: json |> field("url", string),
            height: json |> field("height", int),
            width: json |> field("width", int),
        };

    let artist = json =>
        Json.Decode.{
            name: json |> field("name", string),
        };

    let album = json =>
        Json.Decode.{
            name: json |> field("name", string),
            images: json |> field("images", list(image))
        };

    let track = json =>
        Json.Decode.{
            id: json |> field("id", string),
            uri: json |> field("uri", string),
            name: json |> field("name", string),
            artists: json |> field("artists", list(artist)),
            album: json |> field("album", album),
            durationMs: json |> field("duration_ms", int)
        };

    let tracks = json =>
        Json.Decode.{
            items: json |> at(["tracks", "items"], list(track)),
            total: json |> at(["tracks", "total"], int)
        };

    let device = json =>
        Json.Decode.{
            id: json |> field("id", string),
            name: json |> field("name", string)
        };

    let user = json =>
        Json.Decode.{
            id: json |> field("id", string),
        };

    let player = json =>
        Json.Decode.{
            device: json |> field("device", device),
            isPlaying: json |> field("is_playing", bool),
            progressMs: json |> field("progress_ms", int),
        };
};

let getTracks = (token: string, query: string) => {
    open Utils;

    let url = baseUrl ++ "/search?q=" ++ encodeURIComponent(query) ++ "&type=track";

    Js.Promise.(
        Fetch.fetchWithInit(
            url,
            Fetch.RequestInit.make(
                ~method_=Get,
                ~headers=Fetch.HeadersInit.make({"Authorization": "Bearer " ++ token}),
                ()
            )
        )
        |> then_(Fetch.Response.json)
        |> then_(json => json |> Decode.tracks |> (tracks => Some(tracks) |> resolve))
        |> catch(err => {
            Js.log(err);
            resolve(None)
        })
    );
};

let getUser = (token: string) => {
    let url = baseUrl ++ "/me";

    Js.Promise.(
        Fetch.fetchWithInit(
            url,
            Fetch.RequestInit.make(
                ~method_=Get,
                ~headers=Fetch.HeadersInit.make({"Authorization": "Bearer " ++ token}),
                ()
            )
        )
        |> then_(Fetch.Response.json)
        |> then_(json => json |> Decode.user |> (user => Some(user) |> resolve))
        |> catch(err => {
            Js.log(err);
            resolve(None)
        })
    );
}

let getPlayer = (token: string) => {
    let url = baseUrl ++ "/me/player";

    Js.Promise.(
        Fetch.fetchWithInit(
            url,
            Fetch.RequestInit.make(
                ~method_=Get,
                ~headers=Fetch.HeadersInit.make({"Authorization": "Bearer " ++ token}),
                ()
            )
        )
        |> then_(Fetch.Response.json)
        |> then_(json => json |> Decode.player |> (player => Some(player) |> resolve))
        |> catch(err => {
            Js.log(err);
            resolve(None)
        })
    );
};


let playTrack = (token: string, songUri: string, positionMs: int) => {
    let url = baseUrl ++ "/me/player/play";
    let payload = Js.Dict.empty();

    Js.Dict.set(payload, "uris", Js.Json.array([|Js.Json.string(songUri)|]));

    if (positionMs !== 0) {
        Js.Dict.set(payload, "position_ms", Js.Json.number(positionMs |> float_of_int));
    }

    Js.Promise.(
        Fetch.fetchWithInit(
            url,
            Fetch.RequestInit.make(
                ~method_=Put,
                ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(payload))),
                ~headers=Fetch.HeadersInit.make({
                    "Authorization": "Bearer " ++ token,
                    "Content-Type": "application/json",
                    "Accept": "application/json"

                }),
                ()
            )
        )
        |> then_(Fetch.Response.json)
        |> then_(json => json |> Decode.player |> (player => Some(player) |> resolve))
        |> catch(err => {
            Js.log(err);
            resolve(None)
        })
    );
}

