module Styles = {
  open CssJs

  let wrapper = style(. [
    display(#flex),
    flexDirection(row),
    flexWrap(wrap),
    position(absolute),
    left(zero),
    bottom(zero),
    padding(px(16)),
  ])
}

@react.component
let make = (~dispatch, ~socket: SocketIO.socket, ~state: Types.state) => {
  React.useEffect1(() => {
    switch state.user {
    | Some(user) => socket->SocketIO.emit("addUser", user)
    | None => ()
    }
    None
  }, [state.user])

  let handleNewUserList = React.useCallback1((userList: array<(string, string)>) => {
    Types.UpdateUserList(userList)->dispatch

    Js.log2("newUserList received!", userList)
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
    ->Belt.Array.map(((user, color)) => {
      <div style={ReactDOM.Style.make(~color, ())}> {React.string(user)} </div>
    })
    ->React.array
  }

  <div className=Styles.wrapper> {content} </div>
}
