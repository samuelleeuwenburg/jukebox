let errorStyle = ReactDOMRe.Style.make(~color="#ff0000", ~fontWeight="bold", ());

module Track = {
    [@react.component]
    let make = (~dispatch, ~track: Bragi.track, ~user: Spotify.user) => {
        let voteTrack = React.useCallback0(() => {
            Bragi.vote(user, track)
            |> Js.Promise.then_(_ => {
                Bragi.getQueue();
            })
            |> Js.Promise.then_(queue => {
                dispatch(Types.UpdateQueue(queue));
                Js.Promise.resolve(queue);
            }) |> ignore;
        });
        <li>
            <strong>{React.string("+" ++ string_of_int(track.upvotes) ++ " ")}</strong>
            <button onClick={_ => voteTrack()}>{React.string("vote")}</button>
            {React.string(" - " ++ track.name)}
        </li>
    }
};

[@react.component]
let make = (~dispatch, ~state: Types.state) => {
    React.useEffect0(() => {
        Js.Promise.(
            Bragi.getQueue()
            |> then_(queue => {
                dispatch(Types.UpdateQueue(queue))
                resolve(queue)
            })
        ) |> ignore;
        None;
    });

    let tracks = state.queue
    ->Belt.Option.flatMap(queue => {
        state.user->Belt.Option.map(user => (queue, user));
    })
    ->Belt.Option.map(values => {
        open Bragi;
        let (queue, user) = values;
        let tracks = queue.tracks
        |> List.map(track => <Track key=track.spotifyTrackId dispatch=dispatch track=track user=user />)
        |> Array.of_list
        |> React.array;

        <ul>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(
        <p style=(errorStyle)>{React.string("ERROR: no queue found!")}</p>
    );


    <>
        <h2>{React.string("Queue:")}</h2>
        {tracks}
    </>
};
