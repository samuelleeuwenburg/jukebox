module Track = {
    [@react.component]
    let make = (~track: Spotify.track, ~token: string) => {
        let artist = List.hd(track.artists);

        let playSong = React.useCallback0(() => {
            Spotify.playTrack(token, track.uri, 0)
            |> ignore;
        });

        <li>
            <strong>{React.string(artist.name)}</strong>
            {React.string(" - ")}
            {React.string(track.name)}
            <button onClick={_ => playSong()}>
                {React.string("playSong")}
            </button>
        </li>
    };
};

[@react.component]
let make = (~dispatch, ~token: string, ~state: Types.state) => {
    let clearSearch = React.useCallback0(() => {
        dispatch(Types.ClearSearch);
    });

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
        |> List.map(track => <Track token=token track=track key=track.uri />)
        |> Array.of_list
        |> React.array;

        <ul>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(React.null);

    <>
        <input
            value={state.query} 
            onChange={event => dispatch(Types.UpdateQuery(ReactEvent.Form.target(event)##value))}
        />
        <button onClick={_ => clearSearch()}>{React.string("clear")}</button>
        <button onClick={_ => getTracks()}>{React.string("search")}</button>
        {results}
    </>
};
