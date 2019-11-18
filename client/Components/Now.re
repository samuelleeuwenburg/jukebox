[@react.component]
let make = (~dispatch, ~state: Types.state, ~token: string) => {
    React.useEffect0(() => {
        IO.socketOn(state.socket, "currentTrackUpdate", (json) => {
            let track = json |> Bragi.Decode.track;
            Spotify.playTrack(token, track.uri, 0);
            dispatch(Types.UpdateCurrentTrack(track)) |> ignore;
        });

        //@TODO use date to accurately measure time
        Js.Global.setInterval(() => dispatch(Types.Tick), 100);

        Js.Promise.(
            Bragi.getCurrentTrack()
            |> then_(currentTrack => {
                dispatch(Types.UpdateCurrentTrackAndCursor(currentTrack));
                Spotify.playTrack(token, currentTrack.track.uri, currentTrack.cursor);
                resolve(currentTrack)
            })
        ) |> ignore;
        None;
    });

    state.currentTrack
    ->Belt.Option.map(currentTrack => {
        let fraction = float_of_int(currentTrack.cursor) /. float_of_int(currentTrack.track.durationMs);
        let percentage = floor(fraction *. 100.0);
        <>
            <h2>{React.string("Now playing:")}</h2>
            <p>
                {React.string(currentTrack.track.name)}
                {React.string(" - ")}
                {React.string(string_of_float(percentage) ++ "%")}
            </p>
        </>
    })
    ->Belt.Option.getWithDefault(React.null);
};

