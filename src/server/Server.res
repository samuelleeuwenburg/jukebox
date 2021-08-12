// monkeypatch fetch
%%raw(`
  const fetch = require('node-fetch');
  global.fetch = fetch;
`)

@val external __dirname: string = "__dirname"

module Path = {
  @module("path") external resolve: (string, string) => string = "resolve"
  @module("path") @variadic external join: array<string> => string = "join"
}

let app = Express.express()
let server = Http.createServer(app)
let io = SocketIO.Server.server(server)

let (getState, dispatch) = ServerState.init(ServerState.update, ServerState.initialState)

io->SocketIO.Server.on("connect", Connection.handle(io, getState, dispatch))

Express.App.useOnPath(
  app,
  ~path="/",
  {
    let options = Express.Static.defaultOptions()
    let path = Path.join([__dirname, "../../public"])
    Express.Static.make(path, options) |> Express.Static.asMiddleware
  },
)

server->Http.listen(3000, () => {
  Js.Global.setInterval(() => ServerState.Tick->dispatch->ignore, 500) |> ignore

  Js.Global.setInterval(() => {
    let state = getState()

    switch state.currentTrack {
    | None =>
      if state.tracks->Belt.Array.length != 0 {
        let track = state.tracks[0]
        ServerState.RemoveTrack(track.track.id)->dispatch->ignore
        ServerState.PlayTrack(track)->dispatch->ignore

        let state = getState()
        let json = {
          open Json.Encode
          object_(list{
            ("tracks", state.tracks |> array(Types.Encode.track)),
            ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
          })
        }

        io->SocketIO.Server.emit(Types.Socket.SendQueue, json)
      }
    | _ => ()
    }
  }, 2000) |> ignore

  Js.log("jukeboxing on port 3000!")
})
