[@react.component]
let make = (~state: Types.state) => {
    let user = state.user
        ->Belt.Option.map(user => {
            <p>
                <strong>{React.string("user: ")}</strong>
                {React.string(user.displayName)}
            </p>
        })
        ->Belt.Option.getWithDefault(React.null);

    let player = state.player
        ->Belt.Option.map(player => {
            <p>
                <strong>{React.string("device: ")}</strong>
                {React.string(player.device.name)}
            </p>
        })
        ->Belt.Option.getWithDefault(React.null);

    <>
        {user}
        {player}
    </>
};
