@react.component
let make = () => {
  let logout = () => {
    Spotify.Token.clear()
    Utils.goToUrl("/")
  }
  <button onClick={_event => logout()}> {React.string("logout")} </button>
}
