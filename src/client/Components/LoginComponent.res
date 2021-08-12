@react.component
let make = () =>
  <button onClick={_event => Spotify.Token.authenticate()}> {React.string("login")} </button>
