let baseUrl = "https://api.spotify.com/v1";
let clientId = "4f8a771ca0aa41b28424ad9fc737dacc";
let scopes = "user-read-private user-read-email";
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
    name: string,
    artists: list(artist),
    album: album,
    durationMs: int,
}

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

