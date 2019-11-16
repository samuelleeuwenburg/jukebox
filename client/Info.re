let errorStyle = ReactDOMRe.Style.make(~color="#ff0000", ~fontWeight="bold", ());

[@react.component]
let make = (~state: Types.state) => {
    let user = state.user
        ->Belt.Option.map(user => {
            <p>
                <strong>{React.string("user: ")}</strong>
                {React.string(user.displayName)}
            </p>
        })
        ->Belt.Option.getWithDefault(
            <p style=(errorStyle)>{React.string("ERROR: no user found!")}</p>
        );

    let player = state.player
        ->Belt.Option.map(player => {
            <p>
                <strong>{React.string("device: ")}</strong>
                {React.string(player.device.name)}
            </p>
        })
        ->Belt.Option.getWithDefault(
            <p style=(errorStyle)>{React.string("WARNING: no device found!")}</p>
        );

    <>
        {user}
        {player}
    </>
};
