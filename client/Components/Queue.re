module Styles = {
    open Css;

    let error = style([
        color(Style.Colors.error),
        fontWeight(bold),
    ]);
};

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

[@react.component]
let make = (~dispatch, ~state: Types.state, ~token: string) => {
    React.useEffect0(() => {
        Js.Promise.(
            Bragi.getQueue()
            |> then_(queue => {
                dispatch(Types.UpdateQueue(queue));
                resolve(queue)
            })
        ) |> ignore;

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
            <Track key=track.spotifyTrackId dispatch=dispatch track=track user=user />
        })
        |> Array.of_list
        |> React.array;

        <ul>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(
        <p className=Styles.error>{React.string("ERROR: no queue found!")}</p>
    );


    <>
        <h2>{React.string("Queue:")}</h2>
        {tracks}
    </>
};
