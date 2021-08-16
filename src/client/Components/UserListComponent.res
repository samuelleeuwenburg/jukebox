module User = {
  @react.component
  let make = (~user: Types.user) => {
    <span style={ReactDOM.Style.make(~color=user.color, ())}> {React.string(user.id)} </span>
  }
}

module Styles = {
  open CssJs

  let wrapper = style(. [
    position(absolute),
    zIndex(4),
    right(zero),
    bottom(zero),
    padding(px(16)),
    lineHeight(px(22)),
  ])
}

@react.component
let make = (~dispatch, ~socket: SocketIO.socket, ~state: ClientState.state) => {
  let handleNewUserList = React.useCallback1((userList: array<Types.user>) => {
    ClientState.UpdateUserList(userList)->dispatch
  }, [dispatch])

  // listen for new user list
  React.useEffect1(() => {
    socket->SocketIO.on(SocketIO.SendUserList, handleNewUserList)
    Some(() => socket->SocketIO.off(SocketIO.SendUserList, handleNewUserList))
  }, [handleNewUserList])

  let content = switch state.userList {
  | None => React.null
  | Some(userList) =>
    userList
    ->Belt.Array.map(user => {
      <div key={user.id}> <User user /> </div>
    })
    ->React.array
  }

  <div className=Styles.wrapper> content </div>
}
