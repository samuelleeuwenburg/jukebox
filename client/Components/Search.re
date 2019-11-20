module Styles = {
    open Css;

    let input = style([

    ]);

    let resultsContainer = style([
        position(absolute),
        backgroundColor(Style.Colors.darkGray),
        top(px(60)),
        padding2(px(20), px(40)),
        transform(translateX(px(-40)))
    ])
}   

module Track = {
    type partialTrack = {
        id: string,
        name: string,
        uri: string,
        userId: string,
        imageUrl: string,
        durationMs: int,
    };

    [@react.component]
    let make = (~track: Spotify.track, ~token: string, ~user: Spotify.user, ~socket: IO.socket) => {
        let artist = List.hd(track.artists);

        let addTrack = React.useCallback0(() => {
            let image = track.album.images
            |> List.find((image: Spotify.image) => image.width == 640);

            let data = Json.Encode.(object_([
                ("id", string(track.id)),
                ("name", string(track.name)),
                ("uri", string(track.uri)),
                ("userId", string(user.id)),
                ("imageUrl", string(image.url)),
                ("durationMs", int(track.durationMs)),
            ])); 

            Js.log("adding track");
            Js.log(data);
            
            // dispatch(Types.ClearSearch);
            IO.socketEmit(socket, "addTrack", data) |> ignore;
        });

        <li onClick={_ => addTrack()}>{React.string("add")}
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
            <Track socket=state.socket token=token track=track key=track.uri user=user />
        })
        |> Array.of_list
        |> React.array;

        <ul>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(React.null);

    <div className="search-container">
        <div className="search-input-container">
            <input
                className=Styles.input
                placeholder="Search for tracks"
                value={state.query} 
                onChange={event => dispatch(Types.UpdateQuery(ReactEvent.Form.target(event)##value))}
            />
            <button onClick={_ => clearSearch()}>{React.string("clear")}</button>
            <button onClick={_ => getTracks()}>{React.string("search")}</button>
        </div>
        <div className=Styles.resultsContainer>
            {results}
        </div>
    </div>
};
