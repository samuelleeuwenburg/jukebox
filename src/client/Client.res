let socket = SocketIO.Client.io()

switch ReactDOM.querySelector("#app") {
| Some(root) => ReactDOM.render(<AppComponent socket />, root)
| None => ()
}
