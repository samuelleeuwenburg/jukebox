module Styles = {
    open Css;
    let appContainer = style([
        maxWidth(px(1024)),
        margin2(zero, auto),
        padding(px(20)),
        media("(min-width: 640px)", [
            padding(px(40))
         ])
    ]);

    let logoutContainer = style([
    ]);

    let infoContainer = style([
    ]);

    let header = style([
        height(px(60)),
        backgroundColor(Style.Colors.darkerGray),
        width(pct(100.0)),
        padding2(zero, px(20)),
        display(`flex),
        justifyContent(center),
        alignItems(center),
        position(relative),
        media("(min-width: 640px)", [
            padding2(zero, px(40))
        ]) 
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
                ) |> ignore;
                dispatch(Types.UpdateCurrentTrack(currentTrack))
            }
            | Some(current) => {
                if (current.track.id !== currentTrack.track.id) {
                    Spotify.playTrack(
                        token,
                        currentTrack.track.uri,
                        0,
                    ) |> ignore;
                    dispatch(Types.UpdateCurrentTrack(currentTrack))
                }
            }
            };
        }) |> ignore;

        Js.Global.setInterval(() => dispatch(Types.Tick), 160)
        |> ignore;

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



    <>
        <div className=Styles.header>
            <Search dispatch=dispatch token=token state=state />
        </div>
        <div className=Styles.appContainer>
            <Now dispatch=dispatch state=state token=token />
            <Queue dispatch=dispatch state=state token=token />
        </div>
        <div className=Styles.logoutContainer>
            <Logout />
        </div>
        <div className=Styles.infoContainer>
            <Info state=state />
        </div>
    </>
};
