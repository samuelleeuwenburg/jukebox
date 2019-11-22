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

    // get Spotify data
    React.useEffect0(() => {
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

    // get initial queue
    React.useEffect0(() => IO.socketEmit(state.socket, "getQueue", ()));

    // Listen for new queue
    React.useEffect1(() => {
        let handleNewQueue = json => {
            Js.log("newQueue received!");
            Js.log(json);
            let now = json |> Bragi.Decode.now;

            switch (now.tracks) {
            | Some(tracks) => dispatch(Types.UpdateQueue(tracks))
            | None => ()
            };

            switch ((state.currentTrack, now.currentTrack)) {
            | (Some(local), Some(server)) => {
                if (local.track.id !== server.track.id) {
                    Spotify.playTrack(token, server.track.uri, 0) |> ignore;
                    dispatch(Types.UpdateCurrentTrack(server));
                    ()
                }
            }
            | (None, Some(server)) => {
                Spotify.playTrack(token, server.track.uri, server.position) |> ignore;
                dispatch(Types.UpdateCurrentTrack(server));
                ()
            }
            | _ => ()
            };
        };

        IO.socketOn(state.socket, "newQueue", handleNewQueue);
        Some(() => IO.socketOff(state.socket, "newQueue", handleNewQueue));
    }, [|state.currentTrack|]);

    // tick
    React.useEffect0(() => {
        let tick = () => dispatch(Types.Tick);

        let intervalId = Js.Global.setInterval(tick, 200);
        Some(() => Js.Global.clearInterval(intervalId));
    });

    <>
        <div className=Styles.header>
            <Search dispatch=dispatch token=token state=state />
        </div>
        <div className=Styles.appContainer>
            <Now dispatch=dispatch state=state/>
            <Queue dispatch=dispatch state=state />
        </div>
        <div className=Styles.logoutContainer>
            <Logout />
        </div>
        <div className=Styles.infoContainer>
            <Info state=state />
        </div>
    </>
};
