let initialState: Types.state = {
    results: None,
    player: None,
    user: None,
    queue: None,
    currentTrack: None,
    socket: IO.getSocket(Bragi.baseUrl, "/socket.io"),
};

let reducer = (state: Types.state, action: Types.action) => {
    switch (action) {
    | Types.UpdatePlayer(player) => {...state, player: Some(player)}
    | Types.UpdateUser(user) => {...state, user: Some(user)}
    | Types.UpdateQueue(queue) => {...state, queue: Some(queue)}
    | Types.UpdateResults(response) => {...state, results: Some(response)}
    | Types.UpdateCurrentTrack(currentTrack) => {
        {
            ...state,
            currentTrack: Some({
                ...currentTrack,
                timestamp: int_of_float(Js.Date.now()) - currentTrack.position,
            })
        }
    }
    | Types.Tick => {
        state.currentTrack
        ->Belt.Option.map(currentTrack => {
            let position = int_of_float(Js.Date.now()) - currentTrack.timestamp;
            if (position > currentTrack.track.durationMs) {
                {...state, currentTrack: None }
            } else {
                {...state, currentTrack: Some({ ...currentTrack, position })}
            }
        })
        ->Belt.Option.getWithDefault(state);
    }
    | Types.ClearSearch => {...state, results: None}
    | Types.Error => state
    };
};

