module Track = {
    [@react.component]
    let make = (~track: Spotify.track, ~token: string, ~user: Spotify.user, ~dispatch) => {
        let artist = List.hd(track.artists);

        let playTrack = React.useCallback0(() => {
            Spotify.playTrack(token, track.uri, 0) |> ignore;
        });

        let addTrack = React.useCallback0(() => {
            Bragi.addTrack(user, track)
            |> Js.Promise.then_(_ => {
                dispatch(Types.ClearSearch) |> Js.Promise.resolve;
            }) |> ignore;
        });

        <li onClick={_ => addTrack()}>{React.string("add")}
            <button onClick={_ => playTrack()}>{React.string("play")}</button>
            {React.string(" | ")}
            <strong>{React.string(artist.name)}</strong>
            {React.string(" - ")}
            {React.string(track.name)}
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
            |> then_(tracks => {
                dispatch(Types.UpdateResults(tracks));
                resolve(tracks)
            })
        ) |> ignore;
    }, [|state.query|]);

    let results = state.results
    ->Belt.Option.flatMap(results => {
        state.user->Belt.Option.map(user => (results, user));
    })
    ->Belt.Option.map(values => {
        open Spotify;
        let (results, user) = values;
        let tracks = results.items
        |> List.map(track => {

            <div className="search-result-container">
                <Track dispatch=dispatch token=token track=track key=track.uri user=user />
            </div>
        })
        |> Array.of_list
        |> React.array;

        <ul>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(React.null);

    <div className="search-container">
        <div className="search-input-container">
            <input
                value={state.query} 
                onChange={event => dispatch(Types.UpdateQuery(ReactEvent.Form.target(event)##value))}
            />
            <button onClick={_ => clearSearch()}>{React.string("clear")}</button>
            <button onClick={_ => getTracks()}>{React.string("search")}</button>
        </div>
        <div className="search-results-container">
            {results}
        </div>
    </div>
};
