type state = {
    query: string,
    results: option(Spotify.response(Spotify.track)),
};

type action =
    | UpdateQuery(string)
    | Success(Spotify.response(Spotify.track))
    | Error;

let initialState = {
    query: "",
    results: None,
};

let reducer = (state, action) => {
    switch (action) {
    | UpdateQuery(query) => {...state, query: query}
    | Success(response) => {...state, results: Some(response)}
    | Error => state
    };
};

[@react.component]
let make = (~token: string) => {
    let (state, dispatch) = React.useReducer(reducer, initialState);

    let getTracks = React.useCallback1(() => {
        Js.Promise.(
            Spotify.getTracks(token, state.query)
            |> then_(response => {
                switch (response) {
                | Some(t) => dispatch(Success(t))
                | None => dispatch(Error)
                };
                resolve("")
            })
        ) |> ignore;
    }, [|state.query|]);

    let results = state.results
    ->Belt.Option.map(results => {
        open Spotify;

        let tracks = results.items
        |> List.map(track => {
            let artist = List.hd(track.artists);
            <li>
                <strong>{React.string(artist.name)}</strong>
                {React.string(" - ")}
                {React.string(track.name)}
            </li>
        });

        <ul>{React.array(tracks |> Array.of_list)}</ul>
    })
    ->Belt.Option.getWithDefault(React.null);

    <>
        <p>{React.string("Token:" ++ token)}</p>
        <input
            value={state.query} 
            onChange={event => dispatch(UpdateQuery(ReactEvent.Form.target(event)##value))}
        />
        <button onClick={_ => getTracks()}>
            {React.string("search")}
        </button>
        {results}
    </>
};
