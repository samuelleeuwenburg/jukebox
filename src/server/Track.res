module Conn = {
  let handle = (io, socket, getState, dispatch) => {
    socket->SocketIO.on2(Types.Socket.TrackVote, (. user, track) => {
      let user = user->User.fromSpotifyUser

      ServerState.VoteOnTrack(track, user)->dispatch->ignore
      let state: ServerState.state = ServerState.log(Types.Log.TrackVoted(track, user))->dispatch

      let json = {
        open Json.Encode
        object_(list{
          ("tracks", state.tracks |> array(Types.Encode.track)),
          ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
        })
      }

      io->SocketIO.Server.emit(Types.Socket.SendQueue, json)
      io->SocketIO.Server.emit(Types.Socket.SendLog, state.log)
    })

    socket->SocketIO.on2(Types.Socket.TrackAdd, (. user, track) => {
      let user = user->User.fromSpotifyUser
      let track = track->Types.Track.fromSpotifyTrack(user)

      ServerState.AddTrack(track)->dispatch->ignore
      let state = ServerState.log(Types.Log.TrackAdded(track, user))->dispatch

      let json = {
        open Json.Encode
        object_(list{
          ("tracks", state.tracks |> array(Types.Encode.track)),
          ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
        })
      }

      io->SocketIO.Server.emit(Types.Socket.SendQueue, json)
      io->SocketIO.Server.emit(Types.Socket.SendLog, state.log)
    })

    socket->SocketIO.on(Types.Socket.RequestQueue, _ => {
      let state: ServerState.state = getState()

      let json = {
        open Json.Encode
        object_(list{
          ("tracks", state.tracks |> array(Types.Encode.track)),
          ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
        })
      }

      socket->SocketIO.emit(Types.Socket.SendQueue, json)
    })
  }
}
