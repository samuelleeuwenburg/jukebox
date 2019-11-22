type state = {
    results: option(Spotify.response(Spotify.track)),
    player: option(Spotify.player),
    user: option(Spotify.user),
    queue: option(list(Bragi.track)),
    currentTrack: option(Bragi.currentTrack),
    socket: IO.socket,
};

type action =
    | UpdateResults(Spotify.response(Spotify.track))
    | UpdatePlayer(Spotify.player)
    | UpdateUser(Spotify.user)
    | UpdateQueue(list(Bragi.track))
    | UpdateCurrentTrack(Bragi.currentTrack)
    | Tick
    | ClearSearch
    | Error;

