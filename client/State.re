let initialState: Types.state = {
    query: "",
    results: None,
    player: None,
    user: None,
    queue: None,
    currentTrack: None,
    socket: IO.getSocket(Bragi.baseUrl, "/socket.io"),
};

let reducer = (state: Types.state, action: Types.action) => {
    switch (action) {
    | Types.UpdateQuery(query) => {...state, query: query}
    | Types.UpdatePlayer(player) => {...state, player: Some(player)}
    | Types.UpdateUser(user) => {...state, user: Some(user)}
    | Types.UpdateQueue(queue) => {...state, queue: Some(queue)}
    | Types.UpdateResults(response) => {...state, results: Some(response)}
    | Types.UpdateCurrentTrackAndCursor(currentTrack) => {...state, currentTrack: Some(currentTrack)}
    | Types.UpdateCurrentTrack(track, _timestamp) => {
        {
            ...state,
            currentTrack: Some({
                cursor: 0,
                timestamp: int_of_float(Js.Date.now()),
                track: track
            })
        }
    }
    | Types.Tick => {
        state.currentTrack
        ->Belt.Option.map(currentTrack => {
            {
                ...state,
                currentTrack: Some({
                    ...currentTrack,
                    cursor: int_of_float(Js.Date.now()) - currentTrack.timestamp,
                })
            }
        })
        ->Belt.Option.getWithDefault(state);
    }
    | Types.ClearSearch => {...state, query: "", results: None}
    | Types.Error => state
    };
};

