let errorStyle = ReactDOMRe.Style.make(~color="#ff0000", ~fontWeight="bold", ());

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
    ->Belt.Option.map(queue => {
        open Bragi;

        let tracks = queue.tracks
        |> List.map(track => <li key=track.id>{React.string(track.name)}</li>)
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
