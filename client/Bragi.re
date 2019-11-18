let baseUrl = "http://127.0.0.1:3000";
let baseApiUrl = baseUrl ++ "/api";

type track = {
    id: int,
    spotifyTrackId: string,
    name: string,
    uri: string,
    userId: string,
    durationMs: int,
    upvotes: int
};

type queue = {
    tracks: list(track)
};

type currentTrack = {
    cursor: int,
    track: track
};

type now = {
    cursor: int
};

module Decode = {
    let track = json =>
        Json.Decode.{
            id: json |> field("id", int),
            spotifyTrackId: json |> field("spotify_track_id", string),
            name: json |> field("track_name", string),
            uri: json |> field("track_uri", string),
            userId: json |> field("user_id", string),
            durationMs: json |> field("duration_ms", int),
            upvotes: json |> field("upvotes", int),
        };

    let queue = json =>
        Json.Decode.{
            tracks: json |> field("tracks", list(track))
        };

    let now = json =>
        Json.Decode.{
            cursor: json |> field("cursor", int),
        };

    let currentTrack = json =>
        Json.Decode.{
            cursor: json |> field("cursor", int),
            track: json |> field("track", track)
        };
};

let getQueue = () => {
    let url = baseApiUrl ++ "/queue";

    Js.Promise.(
        Fetch.fetchWithInit(
            url,
            Fetch.RequestInit.make(
                ~method_=Get,
                ~headers=Fetch.HeadersInit.make({
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                }),
                ()
            )
        )
        |> then_(Fetch.Response.json)
        |> then_(json => json |> Decode.queue |> resolve)
    );
};

let addTrack = (user: Spotify.user, track: Spotify.track) => {
    let url = baseApiUrl ++ "/queue";
    let payload = Js.Dict.empty();

    Js.Dict.set(payload, "track_name", Js.Json.string(track.name));
    Js.Dict.set(payload, "track_uri", Js.Json.string(track.uri));
    Js.Dict.set(payload, "spotify_track_id", Js.Json.string(track.id));
    Js.Dict.set(payload, "duration_ms", Js.Json.number(track.durationMs |> float_of_int));
    Js.Dict.set(payload, "user_id", Js.Json.string(user.id));

    Js.Promise.(
        Fetch.fetchWithInit(
            url,
            Fetch.RequestInit.make(
                ~method_=Post,
                ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(payload))),
                ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
                ()
            )
        )
        |> then_(Fetch.Response.text)
    );
};

let vote = (user: Spotify.user, track: track) => {
    let url = baseApiUrl ++ "/vote";
    let payload = Js.Dict.empty();

    Js.Dict.set(payload, "track_name", Js.Json.string(track.name));
    Js.Dict.set(payload, "track_uri", Js.Json.string(track.uri));
    Js.Dict.set(payload, "spotify_track_id", Js.Json.string(track.spotifyTrackId));
    Js.Dict.set(payload, "duration_ms", Js.Json.number(track.durationMs |> float_of_int));
    Js.Dict.set(payload, "user_id", Js.Json.string(user.id));

    Js.Promise.(
        Fetch.fetchWithInit(
            url,
            Fetch.RequestInit.make(
                ~method_=Post,
                ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(payload))),
                ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
                ()
            )
        )
        |> then_(Fetch.Response.text)
    );
};

