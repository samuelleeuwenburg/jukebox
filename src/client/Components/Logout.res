@react.component
let make = () => {
  let logout = () => {
    // Utils.clearToken()
    Utils.goToUrl("/")
  }
  <button onClick={_event => logout()}> {React.string("logout")} </button>
}
