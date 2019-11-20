[@react.component]
let make = (~dispatch, ~state: Types.state, ~token: string) => {
    state.currentTrack
    ->Belt.Option.map(currentTrack => {
        let fraction = float_of_int(currentTrack.position) /. float_of_int(currentTrack.track.durationMs);
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

