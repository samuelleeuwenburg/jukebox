type state = {
    query: string,
    results: option(Spotify.response(Spotify.track)),
    player: option(Spotify.player),
    user: option(Spotify.user),
    queue: option(Bragi.queue),
};

type action =
    | UpdateQuery(string)
    | Success(Spotify.response(Spotify.track))
    | UpdatePlayer(Spotify.player)
    | UpdateUser(Spotify.user)
    | UpdateQueue(Bragi.queue)
    | ClearSearch
    | Error;

