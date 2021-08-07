module Styles = {
  open CssJs

  let wrapper = style(. [
    position(absolute),
    left(zero),
    bottom(zero),
    padding(px(16)),
    lineHeight(px(22)),
  ])
}

@react.component
let make = (~dispatch, ~socket: SocketIO.socket, ~state: Types.state) => {
  let handleNewUserList = React.useCallback1((userList: array<Types.user>) => {
    Types.UpdateUserList(userList)->dispatch
  }, [dispatch])

  // listen for new user list
  React.useEffect1(() => {
    socket->SocketIO.on("newUserList", handleNewUserList)
    Some(() => socket->SocketIO.off("newUserList", handleNewUserList))
  }, [handleNewUserList])

  let content = switch state.userList {
  | None => React.null
  | Some(userList) =>
    userList
    ->Belt.Array.map(user => {
      <div key={user.id} style={ReactDOM.Style.make(~color=user.color, ())}>
        {React.string(user.id)}
      </div>
    })
    ->React.array
  }

  <div className=Styles.wrapper> content </div>
}
