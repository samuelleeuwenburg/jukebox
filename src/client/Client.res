let socket = SocketIO.Client.io()

switch ReactDOM.querySelector("#app") {
| Some(root) => ReactDOM.render(<App socket />, root)
| None => ()
}
