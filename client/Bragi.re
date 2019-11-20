let baseUrl = "http://127.0.0.1:3000";
let baseApiUrl = baseUrl ++ "/api";

type track = {
    id: string,
    name: string,
    uri: string,
    userId: string,
    imageUrl: string,
    durationMs: int,
    upvotes: list(string), 
    timestamp: int,
};

type queue = {
    tracks: list(track)
};

type currentTrack = {
    track: track,
    position: int,
    timestamp: int,
};

module Decode = {
    let track = json =>
        Json.Decode.{
            id: json |> field("id", string),
            name: json |> field("name", string),
            uri: json |> field("uri", string),
            userId: json |> field("userId", string),
            durationMs: json |> field("durationMs", int),
            upvotes: json |> field("upvotes", list(string)),
            imageUrl: json |> field("imageUrl", string),
            timestamp: json |> field("timestamp", int),
        };

    let queue = json =>
        Json.Decode.{
            tracks: json |> field("tracks", list(track))
        };

    let currentTrack = json =>
        Json.Decode.{
            track: json |> at(["currentTrack", "track"], track),
            position: json |> at(["currentTrack", "position"], int),
            timestamp: json |> at(["currentTrack", "timestamp"], int),
        };
};

