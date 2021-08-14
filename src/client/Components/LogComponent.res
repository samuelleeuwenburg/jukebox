@send external scrollTo: (Dom.element, int, int) => unit = "scrollTo"

module Message = {
  module Styles = {
    open CssJs
    let highlight = style(. [color(hex("fff"))])
  }
  @react.component
  let make = (~message: Types.Log.message) => {
    switch message {
    | Types.Log.UserJoined(user) => <>
        <strong> <UserListComponent.User user /> </strong> {React.string(" joined")}
      </>
    | Types.Log.UserLeft(user) => <>
        <strong> <UserListComponent.User user /> </strong> {React.string(" left")}
      </>
    | Types.Log.TrackAdded(track, user) => <>
        <strong> <UserListComponent.User user /> </strong>
        {React.string(" added ")}
        <strong className=Styles.highlight> {React.string(track.track.name)} </strong>
        {React.string(" to the queue")}
      </>
    | Types.Log.TrackVoted(track, user) => <>
        <strong> <UserListComponent.User user /> </strong>
        {React.string(" voted on ")}
        <strong className=Styles.highlight> {React.string(track.track.name)} </strong>
      </>
    }
  }
}

module Styles = {
  open CssJs

  let wrapper = style(. [
    position(absolute),
    left(zero),
    bottom(zero),
    padding(px(16)),
    lineHeight(px(22)),
    width(pct(100.0)),
    overflowY(hidden),
    opacity(0.4),
    background(rgba(20, 21, 24, #percent(0.0))),
    zIndex(1),
    maxHeight(px(150)),
    hover([overflowY(scroll), opacity(1.0), background(rgba(20, 21, 24, #num(0.8))), zIndex(3)]),
  ])

  let timestamp = style(. [paddingRight(px(8)), opacity(0.6)])

  let message = style(. [])
}

let toReadable = (timestamp: float) => {
  open Js.Date
  let date = timestamp->fromFloat
  `${date->getHours->Belt.Float.toString}:${date->getMinutes->Belt.Float.toString}`
}

@react.component
let make = (~dispatch, ~socket: SocketIO.socket, ~state: ClientState.state) => {
  let wrapper = React.useRef(Js.Nullable.null)

  let handleNewLog = React.useCallback1(log => {
    ClientState.UpdateLog(log)->dispatch
  }, [dispatch])

  React.useEffect1(() => {
    socket->SocketIO.on(Types.Socket.SendLog, handleNewLog)
    Some(() => socket->SocketIO.off(Types.Socket.SendLog, handleNewLog))
  }, [handleNewLog])

  React.useEffect1(() => {
    switch wrapper.current->Js.Nullable.toOption {
    | Some(element) => element->scrollTo(0, 90000)
    | None => ()
    }
    None
  }, [state.log])

  switch state.log {
  | None => React.null
  | Some(logs) => {
      let logs = logs->Belt.Array.map(log => {
        <div>
          <span className=Styles.timestamp> {React.string(log.timestamp->toReadable)} </span>
          <span className=Styles.message> <Message message=log.message /> </span>
        </div>
      })

      <div ref={ReactDOM.Ref.domRef(wrapper)} className=Styles.wrapper> {React.array(logs)} </div>
    }
  }
}
