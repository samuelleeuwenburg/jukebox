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
    media("(min-width: 640px)", list{
      padding2(~v=zero, ~h=px(40))
    }),
  })
}
@react.component
let make = (~token: string) => {
  let (state, dispatch) = React.useReducer(State.reducer, State.initialState)

  // get Spotify data
  React.useEffect0(() => {
    {
      open Js.Promise
      Spotify.getPlayer(token) |> then_(player => {
        dispatch(Types.UpdatePlayer(player))
        resolve(player)
      })
    } |> ignore

    {
      open Js.Promise
      Spotify.getUser(token) |> then_(user => {
        dispatch(Types.UpdateUser(user))
        resolve(user)
      })
    } |> ignore

    None
  })

  // get initial queue
  React.useEffect0(() => IO.socketEmit(state.socket, "getQueue", ()))

  // Listen for new queue
  React.useEffect1(() => {
    let handleNewQueue = json => {
      let now = json |> Bragi.Decode.now
      Js.log("newQueue received!")
      Js.log(json)

      switch now.tracks {
      | Some(tracks) => dispatch(Types.UpdateQueue(tracks))
      | None => ()
      }

      switch (state.currentTrack, now.currentTrack) {
      | (Some(local), Some(server)) =>
        if local.track.id !== server.track.id {
          Spotify.playTrack(token, server.track.uri, 0.0) |> ignore
          dispatch(Types.UpdateCurrentTrack(server))
          ()
        }
      | (None, Some(server)) =>
        Spotify.playTrack(token, server.track.uri, server.position) |> ignore
        dispatch(Types.UpdateCurrentTrack(server))
        ()
      | _ => ()
      }
    }

    IO.socketOn(state.socket, "newQueue", handleNewQueue) |> ignore
    Some(() => IO.socketOff(state.socket, "newQueue", handleNewQueue))
  }, [state.currentTrack])

  // tick
  React.useEffect0(() => {
    let tick = () => dispatch(Types.Tick)

    let intervalId = Js.Global.setInterval(tick, 200)
    Some(() => Js.Global.clearInterval(intervalId))
  })

  <>
    <div className=Styles.header> <Search dispatch token state /> </div>
    <div className=Styles.appContainer> <Now dispatch state /> <Queue dispatch state /> </div>
    <div className=Styles.logoutContainer> <Logout /> </div>
    <div className=Styles.infoContainer> <Info state /> </div>
  </>
}
