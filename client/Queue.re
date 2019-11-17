let errorStyle = ReactDOMRe.Style.make(~color="#ff0000", ~fontWeight="bold", ());

module Track = {
    [@react.component]
    let make = (~dispatch, ~track: Bragi.track, ~user: Spotify.user) => {
        let voteTrack = React.useCallback0(() => {
            Bragi.vote(user, track) |> ignore;
        });
        <li>
            <strong>{React.string("+" ++ string_of_int(track.upvotes) ++ " ")}</strong>
            <button onClick={_ => voteTrack()}>{React.string("vote")}</button>
            {React.string(" - " ++ track.name)}
        </li>
    }
};

module CurrentTrack = {
    [@react.component]
    let make = (~dispatch, ~state: Types.state) => {
        React.useEffect0(() => {
            IO.socketOn(state.socket, "trackProgressUpdate", (json) => {
                let currentTrack = json |> Bragi.Decode.currentTrack;
                dispatch(Types.UpdateCurrentTrack(currentTrack)) |> ignore;
            });
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
};

[@react.component]
let make = (~dispatch, ~state: Types.state) => {
    React.useEffect0(() => {
        IO.socketOn(state.socket, "queueUpdate", (json) => {
            let queue = json |> Bragi.Decode.queue;
            dispatch(Types.UpdateQueue(queue)) |> ignore;
        });
    });

    let tracks = state.queue
    ->Belt.Option.flatMap(queue => {
        state.user->Belt.Option.map(user => (queue, user));
    })
    ->Belt.Option.map(values => {
        open Bragi;
        let (queue, user) = values;
        let tracks = queue.tracks
        |> List.map(track => {
            <div className="queue-track-container">
                <Track key=track.spotifyTrackId dispatch=dispatch track=track user=user />
            </div>
        })
        |> Array.of_list
        |> React.array;

        <ul>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(
        <p style=(errorStyle)>{React.string("ERROR: no queue found!")}</p>
    );


    <div className="queue-container">
        <CurrentTrack dispatch=dispatch state=state />
        <h2>{React.string("Queue:")}</h2>
        {tracks}
    </div>
};
