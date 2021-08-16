module Conn = {
  let handle = (io, socket, getState, dispatch) => {
    socket->SocketIO.on2(SocketIO.TrackVote, (. user, track) => {
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

      io->SocketIO.Server.emit(SocketIO.SendQueue, json)
      io->SocketIO.Server.emit(SocketIO.SendLog, state.log)
    })

    socket->SocketIO.on2(SocketIO.TrackAdd, (. user, track) => {
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

      io->SocketIO.Server.emit(SocketIO.SendQueue, json)
      io->SocketIO.Server.emit(SocketIO.SendLog, state.log)
    })

    socket->SocketIO.on(SocketIO.RequestQueue, _ => {
      let state: ServerState.state = getState()

      let json = {
        open Json.Encode
        object_(list{
          ("tracks", state.tracks |> array(Types.Encode.track)),
          ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
        })
      }

      socket->SocketIO.emit(SocketIO.SendQueue, json)
    })
  }
}
