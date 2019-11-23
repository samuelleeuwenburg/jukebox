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



    <>
        {user}

    </>
};
