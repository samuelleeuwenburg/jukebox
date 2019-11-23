let baseUrl = "http://127.0.0.1:3000";
let baseApiUrl = baseUrl ++ "/api";

type track = {
    id: string,
    name: string,
    artist: string,
    uri: string,
    userId: string,
    imageUrl: string,
    durationMs: int,
    upvotes: list(string), 
    timestamp: int,
};


type currentTrack = {
    track: track,
    position: int,
    timestamp: int,
};

type now = {
    tracks: option(list(track)),
    currentTrack: option(currentTrack),
};

module Decode = {
    let track = json =>
        Json.Decode.{
            id: json |> field("id", string),
            name: json |> field("name", string),
            artist: json |> field("artist", string),
            uri: json |> field("uri", string),
            userId: json |> field("userId", string),
            durationMs: json |> field("durationMs", int),
            upvotes: json |> field("upvotes", list(string)),
            imageUrl: json |> field("imageUrl", string),
            timestamp: json |> field("timestamp", int),
        };

    let currentTrack = json =>
        Json.Decode.{
            track: json |> field("track", track),
            position: json |> field("position", int),
            timestamp: json |> field("timestamp", int),
        };

    let now = json =>
        Json.Decode.{
            tracks: json |> field("tracks", optional(list(track))),
            currentTrack: json |> field("currentTrack", optional(currentTrack)),
        }
};

