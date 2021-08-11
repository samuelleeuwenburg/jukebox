module Styles = {
  open CssJs

  let appContainer = style(. [
    maxWidth(px(1024)),
    margin2(~v=zero, ~h=auto),
    padding(px(20)),
    media("(min-width: 640px)", [padding(px(40))]),
  ])

  let logoutContainer = style(. [position(absolute), bottom(zero), right(zero), padding(px(16))])

  let header = style(. [
    height(px(60)),
    backgroundColor(Style.Colors.darkerGray),
    width(pct(100.0)),
    padding2(~v=zero, ~h=px(20)),
    display(#flex),
    justifyContent(center),
    alignItems(center),
    position(relative),
    media("(min-width: 640px)", [padding2(~v=zero, ~h=px(40))]),
  ])
}

@react.component
let make = (~dispatch, ~socket: SocketIO.socket, ~state: Types.state) => {
  let (currentTrack, setCurrentTrack) = React.useState(() => state.currentTrack)

  // get Spotify data
  React.useEffect0(() => {
    switch Spotify.Token.get(socket) {
    | Some(token) => {
        Spotify.getPlayer(token)
        |> Js.Promise.then_(player => {
          dispatch(Types.UpdatePlayer(player))
          Js.Promise.resolve(player)
        })
        |> ignore

        Spotify.getUser(token)
        |> Js.Promise.then_(user => {
          dispatch(Types.UpdateSpotifyUser(user))
          Js.Promise.resolve(user)
        })
        |> ignore
      }
    | None => ()
    }

    None
  })

  React.useEffect1(() => {
    switch (Spotify.Token.get(socket), state.currentTrack, currentTrack) {
    | (Some(token), Some(server), Some(local)) =>
      if local.track.track.id !== server.track.track.id {
        Spotify.playTrack(token, server.track.track.uri, 0.0)->ignore
        setCurrentTrack(_ => state.currentTrack)
      }
    | (Some(token), Some(server), None) => {
        Spotify.playTrack(token, server.track.track.uri, server.position)->ignore
        setCurrentTrack(_ => state.currentTrack)
      }
    | _ => ()
    }
    None
  }, [state.currentTrack])

  <>
    <div className=Styles.header> <Search socket dispatch state /> </div>
    <div className=Styles.appContainer>
      <Now dispatch state /> <Queue socket dispatch state />
    </div>
    <div className=Styles.logoutContainer> <Logout /> </div>
    <UserList dispatch socket state />
  </>
}
