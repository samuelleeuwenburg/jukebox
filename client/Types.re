type state = {
    query: string,
    results: option(Spotify.response(Spotify.track)),
    player: option(Spotify.player),
    user: option(Spotify.user),
    queue: option(Bragi.queue),
    currentTrack: option(Bragi.currentTrack),
    socket: IO.socket,
};

type action =
    | UpdateQuery(string)
    | UpdateResults(Spotify.response(Spotify.track))
    | UpdatePlayer(Spotify.player)
    | UpdateUser(Spotify.user)
    | UpdateQueue(Bragi.queue)
    | UpdateCurrentTrack(Bragi.track)
    | UpdateCurrentTrackAndCursor(Bragi.currentTrack)
    | Tick
    | ClearSearch
    | Error;

