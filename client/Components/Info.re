module Styles = {
    open Css;

    let error = style([
        color(Style.Colors.error),
        fontWeight(bold),
    ]);
};

[@react.component]
let make = (~state: Types.state) => {
    let user = state.user
        ->Belt.Option.map(user => {
            <div>
                <strong>{React.string("user: ")}</strong>
                {React.string(user.displayName)}
            </div>
        })
        ->Belt.Option.getWithDefault(
            <div className=Styles.error>{React.string("ERROR: no user found!")}</div>
        );

    let player = state.player
        ->Belt.Option.map(player => {
            <div>
                <strong>{React.string("device: ")}</strong>
                {React.string(player.device.name)}
            </div>
        })
        ->Belt.Option.getWithDefault(
            <div className=Styles.error>{React.string("WARNING: no device found!")}</div>
        );

    <>
        {user}
        {player}
    </>
};
