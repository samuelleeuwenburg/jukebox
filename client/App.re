module Styles = {
    open Css;

    let appContainer = style([
        maxWidth(px(1024)),
        margin2(zero, auto)
    ]);

}
[@react.component]
let make = (~token: string) => {
    let (state, dispatch) = React.useReducer(State.reducer, State.initialState);
    React.useEffect0(() => {
        IO.socketEmit(state.socket, "getQueue", ());
        IO.socketOn(state.socket, "newQueue", (json) => {
            Js.log("newQueue received!");
            Js.log(json);
            let queue = json |> Bragi.Decode.queue;
            let currentTrack = json |> Bragi.Decode.currentTrack;
            dispatch(Types.UpdateQueue(queue));

            switch (state.currentTrack) {
            | None => {
                Spotify.playTrack(
                    token,
                    currentTrack.track.uri,
                    currentTrack.position,
                );
                dispatch(Types.UpdateCurrentTrack(currentTrack))
            }
            | Some(current) => {
                if (current.track.id !== currentTrack.track.id) {
                    Spotify.playTrack(
                        token,
                        currentTrack.track.uri,
                        0,
                    );
                    dispatch(Types.UpdateCurrentTrack(currentTrack))
                }
            }
            };
        }) |> ignore;

        Js.Global.setInterval(() => dispatch(Types.Tick), 160);

        Js.Promise.(
            Spotify.getPlayer(token)
            |> then_(player => {
                dispatch(Types.UpdatePlayer(player))
                resolve(player)
            })
        ) |> ignore;

        Js.Promise.(
            Spotify.getUser(token)
            |> then_(user => {
                dispatch(Types.UpdateUser(user));
                resolve(user)
            })
        ) |> ignore;
        None;
    });

    <div className=Styles.appContainer>
        <Info state=state />
        <Search dispatch=dispatch state=state token=token />
        <Now dispatch=dispatch state=state token=token />
        <Queue dispatch=dispatch state=state token=token />
    </div>
};
