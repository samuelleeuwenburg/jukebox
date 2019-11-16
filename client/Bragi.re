let baseUrl = "http://127.0.0.1:3000/api";

module Decode = {
};

let getQueue = () => {};
let getNow = () => {};

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
                ~method_=Put,
                ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(payload))),
                ~headers=Fetch.HeadersInit.make({
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                }),
                ()
            )
        )
        |> then_(Fetch.Response.json)
    );
};

let vote = (user: Spotify.user, track: Spotify.track) => {};

