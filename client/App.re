let initialState: Types.state = {
    query: "",
    results: None,
    player: None,
    user: None,
    queue: None,
    currentTrack: None,
    socket: IO.getSocket(Bragi.baseUrl),
};

let reducer = (state: Types.state, action: Types.action) => {
    switch (action) {
    | Types.UpdateQuery(query) => {...state, query: query}
    | Types.UpdatePlayer(player) => {...state, player: Some(player)}
    | Types.UpdateUser(user) => {...state, user: Some(user)}
    | Types.UpdateQueue(queue) => {...state, queue: Some(queue)}
    | Types.UpdateResults(response) => {...state, results: Some(response)}
    | Types.UpdateCurrentTrack(currentTrack) => {...state, currentTrack: Some(currentTrack)}
    | Types.ClearSearch => {...state, query: "", results: None}
    | Types.Error => state
    };
};

[@react.component]
let make = (~token: string) => {
    let (state, dispatch) = React.useReducer(reducer, initialState);

    React.useEffect0(() => {
        Js.Promise.(
            Spotify.getPlayer(token)
            |> then_(player => {
                dispatch(Types.UpdatePlayer(player))
                resolve(player)
            })
        ) |> ignore;
        None;
    });

    React.useEffect0(() => {
        Js.Promise.(
            Spotify.getUser(token)
            |> then_(user => {
                dispatch(Types.UpdateUser(user));
                resolve(user)
            })
        ) |> ignore;
        None;
    });

    <div className="row">
        <div className="col-left">
            <Info state=state />
        </div>
        <div className="col-right">
            <div className="sidebar-header">
                <Search dispatch=dispatch token=token state=state />
            </div>
            <Queue dispatch=dispatch state=state />
        </div>
    </div>
};
