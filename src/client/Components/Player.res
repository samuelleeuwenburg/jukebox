module Styles = {
  open Css

  let appContainer = style(list{
    maxWidth(px(1024)),
    margin2(~v=zero, ~h=auto),
    padding(px(20)),
    media("(min-width: 640px)", list{padding(px(40))}),
  })

  let logoutContainer = style(list{})

  let infoContainer = style(list{})

  let header = style(list{
    height(px(60)),
    backgroundColor(Style.Colors.darkerGray),
    width(pct(100.0)),
    padding2(~v=zero, ~h=px(20)),
    display(#flex),
    justifyContent(center),
    alignItems(center),
    position(relative),
    media("(min-width: 640px)", list{padding2(~v=zero, ~h=px(40))}),
  })
}

@react.component
let make = (~dispatch, ~socket: SocketIO.socket, ~state: Types.state) => {
  let (currentTrack, setCurrentTrack) = React.useState(() => state.currentTrack)

  // get Spotify data
  React.useEffect1(() => {
    switch state.token {
    | Some(token) => {
        Spotify.getPlayer(token)
        |> Js.Promise.then_(player => {
          dispatch(Types.UpdatePlayer(player))
          Js.Promise.resolve(player)
        })
        |> ignore

        Spotify.getUser(token)
        |> Js.Promise.then_(user => {
          dispatch(Types.UpdateUser(user))
          Js.Promise.resolve(user)
        })
        |> ignore
      }
    | None => ()
    }

    None
  }, [state.token])

  React.useEffect2(() => {
    switch (state.token, state.currentTrack, currentTrack) {
    | (Some(token), Some(server), Some(local)) => if local.track.id !== server.track.id {
        Spotify.playTrack(token, server.track.uri, 0.0)->ignore
        setCurrentTrack(_ => state.currentTrack)
      }
    | (Some(token), Some(server), None) => {
        Spotify.playTrack(token, server.track.uri, server.position)->ignore
        setCurrentTrack(_ => state.currentTrack)
      }
    | _ => ()
    }
    None
  }, (state.token, state.currentTrack))

  <>
    <div className=Styles.header> <Search socket dispatch state /> </div>
    <div className=Styles.appContainer>
      <Now dispatch state /> <Queue socket dispatch state />
    </div>
    <div className=Styles.logoutContainer> <Logout /> </div>
    <div className=Styles.infoContainer> <Info state /> </div>
  </>
}
