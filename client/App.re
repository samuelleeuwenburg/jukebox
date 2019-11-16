let initialState: Types.state = {
    query: "",
    results: None,
    player: None,
    user: None,
};

let reducer = (state: Types.state, action: Types.action) => {
    switch (action) {
    | Types.UpdateQuery(query) => {...state, query: query}
    | Types.Success(response) => {...state, results: Some(response)}
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
                Js.log(player);
                resolve("")
            })
        ) |> ignore;
        None;
    });

    <>
        <p>{React.string("Token:" ++ token)}</p>
        <Search dispatch=dispatch token=token state=state />
    </>
};
