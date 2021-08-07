@react.component
let make = (~socket: SocketIO.socket) => {
  let (state, dispatch) = React.useReducer(State.reducer, State.initialState)
  let url = RescriptReactRouter.useUrl()

  let handleNewQueue = React.useCallback1(json => {
    let now = Types.Decode.now(json)
    Types.HandleNow(now)->dispatch
  }, [dispatch])

  let handleNewUser = React.useCallback1(json => {
    let user = Types.Decode.user(json)
    Types.UpdateUser(user)->dispatch
  }, [dispatch])

  // get spotify token
  React.useEffect2(() => {
    Utils.getToken(url.hash)->Types.UpdateToken->dispatch
    None
  }, (url.hash, dispatch))

  // get initial queue
  React.useEffect0(() => {
    socket->SocketIO.emit("getQueue", ())
    None
  })

  // add spotify user
  React.useEffect1(() => {
    switch state.spotifyUser {
    | Some(user) => socket->SocketIO.emit("addUser", user)
    | None => ()
    }
    None
  }, [state.spotifyUser])

  // listen for new queue
  React.useEffect1(() => {
    socket->SocketIO.on("newQueue", handleNewQueue)
    Some(() => socket->SocketIO.off("newQueue", handleNewQueue))
  }, [handleNewQueue])

  // listen for new user
  React.useEffect1(() => {
    socket->SocketIO.on("newUser", handleNewUser)
    Some(() => socket->SocketIO.off("newUser", handleNewUser))
  }, [handleNewUser])

  // setup tick
  React.useEffect1(() => {
    let tick = () => dispatch(Types.Tick)
    let intervalId = Js.Global.setInterval(tick, 2000)
    Some(() => Js.Global.clearInterval(intervalId))
  }, [dispatch])

  switch state.token {
  | None => <Login />
  | Some(_) => <Player dispatch state socket />
  }
}
