let baseUrl = "http://127.0.0.1:3000/api";

type track = {
    id: string,
    name: string,
    userId: string,
    durationMs: int,
};

type queue = {
    tracks: list(track)
};

module Decode = {
    let track = json =>
        Json.Decode.{
            id: json |> field("track_id", string),
            name: json |> field("track_name", string),
            userId: json |> field("user_id", string),
            durationMs: json |> field("duration_ms", int),
        };

    let queue = json =>
        Json.Decode.{
            tracks: json |> field("tracks", list(track))
        };
};

let getQueue = () => {
    let url = baseUrl ++ "/queue";

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

// let _getNow = () => {};

let addTrack = (user: Spotify.user, track: Spotify.track) => {
    let url = baseUrl ++ "/queue";
    let payload = Js.Dict.empty();

    Js.Dict.set(payload, "track_name", Js.Json.string(track.name));
    Js.Dict.set(payload, "track_uri", Js.Json.string(track.uri));
    Js.Dict.set(payload, "track_id", Js.Json.string(track.id));
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

// let _vote = (_user: Spotify.user, _track: Spotify.track) => {};

