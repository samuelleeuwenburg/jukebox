module Styles = {
  open CssJs

  let outerWrapper = style(. [
    display(#flex),
    flexDirection(#column),
    alignItems(#center),
    justifyContent(#center),
    height(vh(100.0)),
  ])

  let wrapper = style(. [maxWidth(px(640)), textAlign(center)])

  let step = style(. [
    border(px(1), #solid, hex("fff")),
    borderRadius(pct(50.0)),
    width(px(52)),
    height(px(52)),
    padding(px(16)),
    display(inlineBlock),
    marginRight(px(12)),
  ])

  let button = style(. [
    padding(px(12)),
    margin(px(12)),
    display(inlineBlock),
    background(transparent),
    cursor(pointer),
    color(hex("fff")),
    fontWeight(#bold),
    before([unsafe("content", "'>'"), display(inlineBlock), marginRight(px(12))]),
    hover([transform(scale(1.1, 1.1))]),
  ])
}

@react.component
let make = (~dispatch, ~socket: SocketIO.socket, ~state: ClientState.state) => {
  let (refreshToken, setRefreshToken) = React.useState(_ =>
    Dom.Storage.localStorage |> Dom.Storage.getItem("refresh_token")
  )
  let url = RescriptReactRouter.useUrl()

  let handleNewTokens = (. refreshToken, accessToken, expiresIn) => {
    Js.log2("new refresh token -> ", refreshToken)
    setRefreshToken(_ => Some(refreshToken))
    Spotify.Token.saveRefresh(refreshToken)
    Spotify.Token.saveAccess(accessToken, expiresIn)

    // clear url
    Utils.pushState(Js.Obj.empty(), "", "/")
  }

  // listen for new refresh tokens
  React.useEffect1(() => {
    socket->SocketIO.on3(Types.Socket.SendRefreshToken, handleNewTokens)
    Some(() => socket->SocketIO.off(Types.Socket.SendRefreshToken, handleNewTokens))
  }, [handleNewTokens])

  // request spotify refresh tokens after login
  React.useEffect1(() => {
    open Utils.URLSearchParams

    switch url.search->make->get("code") {
    | None => ()
    | Some(code) => socket->SocketIO.emit2(Types.Socket.RequestRefreshToken, Utils.origin, code)
    }

    None
  }, [url.search])

  let getDevices = React.useCallback1(() => {
    switch Spotify.Token.get(socket) {
    | Some(token) => Spotify.getDevices(token)->Js.Promise.then_(json => {
        open Json.Decode
        let devices = json |> field("devices", array(Spotify.Decode.device))
        ClientState.UpdateDevices(devices)->dispatch
        Js.Promise.resolve(devices)
      }, _)->ignore
    | None => ()
    }
  }, [dispatch])

  let transferPlayback = React.useCallback1(id => {
    switch Spotify.Token.get(socket) {
    | Some(token) =>
      Spotify.transferPlayback(token, id)
      |> Js.Promise.then_(_ => Spotify.getPlayer(token))
      |> Js.Promise.catch(_ => {
        // sometimes it takes a while to switch, wait a little and try again
        Js.Promise.make((~resolve, ~reject as _) =>
          Js.Global.setTimeout(() => resolve(. 0), 1000)->ignore
        ) |> Js.Promise.then_(_ => Spotify.getPlayer(token))
      })
      |> Js.Promise.then_(player => {
        dispatch(ClientState.UpdatePlayer(player))
        Js.Promise.resolve(player)
      })
      |> ignore
    | None => ()
    }
  }, [dispatch])

  // get Spotify devices
  React.useEffect2(() => {
    getDevices()
    None
  }, (dispatch, refreshToken))

  let components = switch (state.devices, refreshToken) {
  | (None, None) => <>
      <h1>
        <span className=Styles.step> {React.string("1")} </span> {React.string("Authorize Spotify")}
      </h1>
      <a className=Styles.button onClick={_event => Spotify.Token.authenticate()}>
        {React.string("Authorize")}
      </a>
    </>
  | (Some(devices), Some(_)) => {
      let devices = devices->Belt.Array.map(device => {
        <a className=Styles.button key=device.id onClick={_ => transferPlayback(device.id)}>
          {React.string(device.name)}
        </a>
      })

      if devices->Belt.Array.length > 0 {
        <>
          <h1>
            <span className=Styles.step> {React.string("2")} </span>
            {React.string("Choose a device to play on")}
          </h1>
          {React.array(devices)}
        </>
      } else {
        <>
          <h1> {React.string("No devices found, is Spotify running?")} </h1>
          <a className=Styles.button onClick={_ => getDevices()}>
            {React.string("Sorry, it is now!")}
          </a>
        </>
      }
    }
  | _ => React.null
  }

  <div className=Styles.outerWrapper> <div className=Styles.wrapper> components </div> </div>
}
