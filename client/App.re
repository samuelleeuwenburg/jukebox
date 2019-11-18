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
        Js.Promise.(
            Spotify.getPlayer(token)
            |> then_(player => {
                dispatch(Types.UpdatePlayer(player))
                resolve(player)
            })
        ) |> ignore;
        None;
    });

    React.useEffect0(() => {
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
        <Search dispatch=dispatch token=token state=state />
        <Now dispatch=dispatch state=state token=token />
        <Queue dispatch=dispatch state=state token=token />
    </div>
};
