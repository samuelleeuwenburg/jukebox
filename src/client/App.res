@react.component
let make = (~socket: SocketIO.socket) => {
  let (state, dispatch) = React.useReducer(State.reducer, State.initialState)
  let (refreshToken, setRefreshToken) = React.useState(_ =>
    Dom.Storage.localStorage |> Dom.Storage.getItem("refresh_token")
  )
  let url = RescriptReactRouter.useUrl()

  let handleNewQueue = React.useCallback1(json => {
    let now = Types.Decode.now(json)
    Js.log2("new queue -> ", json)
    Types.HandleNow(now)->dispatch
  }, [dispatch])

  let handleNewUser = React.useCallback1(json => {
    let user = Types.Decode.user(json)
    Js.log2("new user -> ", user)
    Types.UpdateUser(user)->dispatch
  }, [dispatch])

  let handleNewAccessToken = (. accessToken, expiresIn) => {
    Js.log2("new access token -> ", accessToken)
    Spotify.Token.saveAccess(accessToken, expiresIn)
  }

  let handleNewTokens = (. refreshToken, accessToken, expiresIn) => {
    Js.log2("new refresh token -> ", refreshToken)
    setRefreshToken(_ => Some(refreshToken))
    Spotify.Token.saveRefresh(refreshToken)
    Spotify.Token.saveAccess(accessToken, expiresIn)

    // clear url
    Utils.pushState(Js.Obj.empty(), "", "/")
  }

  // request spotify refresh tokens after login
  React.useEffect1(() => {
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

  // listen for new access token
  React.useEffect1(() => {
    socket->SocketIO.on2("sendNewAccessToken", handleNewAccessToken)
    Some(() => socket->SocketIO.off("sendTokens", handleNewAccessToken))
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

  switch refreshToken {
  | None => <Login />
  | Some(_) => <Player dispatch state socket />
  }
}
