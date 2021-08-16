let withClientSecret = fn => {
  switch Js.Dict.get(Node.Process.process["env"], "CLIENT_SECRET") {
  | None => Js.log("no clientSecret found in ENV")
  | Some(clientSecret) => fn(clientSecret)
  }
}

module Conn = {
  let handle = (_io, socket, _getState, _dispatch) => {
    socket->SocketIO.on(SocketIO.RequestAccessToken, refreshToken => {
      withClientSecret(clientSecret => {
        Spotify.Token.getNewAccessToken(clientSecret, refreshToken)
        |> Js.Promise.then_(json => {
          let token = Json.Decode.field("access_token", Json.Decode.string, json)
          let expiresIn = Json.Decode.field("expires_in", Json.Decode.int, json)
          socket->SocketIO.emit2(SocketIO.SendAccessToken, token, expiresIn)
          Js.Promise.resolve(token)
        })
        |> ignore
      })
    })

    socket->SocketIO.on2(SocketIO.RequestRefreshToken, (. clientURI, code) => {
      open Js.Promise
      withClientSecret(clientSecret => {
        Spotify.Token.getRefresh(clientSecret, clientURI, code)
        |> then_(json => {
          let data = Spotify.Token.Decode.tokenResponse(json)
          socket->SocketIO.emit3(
            SocketIO.SendRefreshToken,
            data.refreshToken,
            data.accessToken,
            data.expiresIn,
          )
          resolve()
        })
        |> ignore
      })
    })
  }
}
