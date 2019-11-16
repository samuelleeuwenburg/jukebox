type state = {
    query: string,
    results: option(Spotify.response(Spotify.track)),
    player: option(Spotify.player),
    user: option(Spotify.user)
};

type action =
    | UpdateQuery(string)
    | Success(Spotify.response(Spotify.track))
    | UpdatePlayer(Spotify.player)
    | UpdateUser(Spotify.user)
    | ClearSearch
    | Error;

