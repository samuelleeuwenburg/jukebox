@react.component
let make = (~socket: SocketIO.socket) => {
  let (state, dispatch) = React.useReducer(ClientState.reducer, ClientState.initialState)

  let handleNewQueue = React.useCallback1(json => {
    let now = Types.Decode.now(json)
    Js.log2("new queue -> ", json)
    ClientState.HandleNow(now)->dispatch
  }, [dispatch])

  let handleNewUser = React.useCallback1(json => {
    let user = Types.Decode.user(json)
    Js.log2("new user -> ", user)
    ClientState.UpdateUser(user)->dispatch
  }, [dispatch])

  let handleNewAccessToken = (. accessToken, expiresIn) => {
    Js.log2("new access token -> ", accessToken)
    Spotify.Token.saveAccess(accessToken, expiresIn)
  }

  // listen for new access token
  React.useEffect1(() => {
    socket->SocketIO.on2(Types.Socket.SendAccessToken, handleNewAccessToken)
    Some(() => socket->SocketIO.off(Types.Socket.SendAccessToken, handleNewAccessToken))
  }, [handleNewAccessToken])

  // get initial queue
  React.useEffect0(() => {
    socket->SocketIO.emit(Types.Socket.RequestQueue, ())
    None
  })

  // add spotify user
  React.useEffect1(() => {
    switch state.spotifyUser {
    | Some(user) => socket->SocketIO.emit(Types.Socket.RequestUser, user)
    | None => ()
    }
    None
  }, [state.spotifyUser])

  // listen for new queue
  React.useEffect1(() => {
    socket->SocketIO.on(Types.Socket.SendQueue, handleNewQueue)
    Some(() => socket->SocketIO.off(Types.Socket.SendQueue, handleNewQueue))
  }, [handleNewQueue])

  // listen for new user
  React.useEffect1(() => {
    socket->SocketIO.on(Types.Socket.SendUser, handleNewUser)
    Some(() => socket->SocketIO.off(Types.Socket.SendUser, handleNewUser))
  }, [handleNewUser])

  // setup tick
  React.useEffect1(() => {
    let tick = () => dispatch(ClientState.Tick)
    let intervalId = Js.Global.setInterval(tick, 2000)
    Some(() => Js.Global.clearInterval(intervalId))
  }, [dispatch])

  switch state.player {
  | None => <SetupComponent dispatch state socket />
  | _ => <PlayerComponent dispatch state socket />
  }
}
