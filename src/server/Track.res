module Conn = {
  let handle = (io, socket, getState, dispatch) => {
    socket->SocketIO.on2(Types.Socket.TrackVote, (. user, trackId) => {
      let user = user->User.fromSpotifyUser

      let state: ServerState.state = ServerState.VoteOnTrack(trackId, user)->dispatch

      let json = {
        open Json.Encode
        object_(list{
          ("tracks", state.tracks |> array(Types.Encode.track)),
          ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
        })
      }

      io->SocketIO.Server.emit(Types.Socket.SendQueue, json)
    })

    socket->SocketIO.on2(Types.Socket.TrackAdd, (. user, track) => {
      let user = user->User.fromSpotifyUser
      let track = track->Types.Track.fromSpotifyTrack(user)

      let state = ServerState.AddTrack(track)->dispatch

      let json = {
        open Json.Encode
        object_(list{
          ("tracks", state.tracks |> array(Types.Encode.track)),
          ("currentTrack", nullable(Types.Encode.currentTrack, state.currentTrack)),
        })
      }

      io->SocketIO.Server.emit(Types.Socket.SendQueue, json)
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
