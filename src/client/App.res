@react.component
let make = (~socket: SocketIO.socket) => {
  let (state, dispatch) = React.useReducer(State.reducer, State.initialState)
  let url = RescriptReactRouter.useUrl()

  let handleNewQueue = React.useCallback2(json => {
    let now = Types.Decode.now(json)
    Types.HandleNow(now)->dispatch

    Js.log2("newQueue received!", now)
  }, (dispatch, state.currentTrack))

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

  // listen for new queue
  React.useEffect1(() => {
    socket->SocketIO.on("newQueue", handleNewQueue)
    Some(() => socket->SocketIO.off("newQueue", handleNewQueue))
  }, [handleNewQueue])

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
