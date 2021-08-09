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

  let handleNewTokens = React.useCallback0((refreshToken, accessToken, expiresIn) => {
    Js.log4("new tokens -> ", refreshToken, accessToken, expiresIn)
    Spotify.Token.saveRefresh(refreshToken)
    Spotify.Token.saveAccess(accessToken, expiresIn)
  })

  // request spotify refresh tokens after login
  React.useEffect1(() => {
    // Utils.getToken(url.hash)->Types.UpdateToken->dispatch
    open Utils.URLSearchParams

    switch url.search->make->get("code") {
    | None => ()
    | Some(code) => socket->SocketIO.emit2("getTokens", Utils.origin, code)
    }

    None
  }, [url.search])

  // listen for new refresh tokens
  React.useEffect1(() => {
    socket->SocketIO.on3("sendTokens", handleNewTokens)
    Some(() => socket->SocketIO.off("sendTokens", handleNewTokens))
  }, [handleNewTokens])

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
