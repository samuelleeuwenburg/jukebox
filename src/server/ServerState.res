type state = {
  tracks: array<Types.track>,
  currentTrack: option<Types.currentTrack>,
  users: array<Types.user>,
  log: array<Types.Log.t>,
}

type action =
  | PlayTrack(Types.track)
  | AddTrack(Types.track)
  | AddUser(Types.user)
  | RemoveUser(Types.user)
  | RemoveTrack(string)
  | VoteOnTrack(Types.track, Types.user)
  | Log(Types.Log.t)
  | Tick

let initialState = {
  tracks: [],
  currentTrack: None,
  users: [],
  log: [],
}

let log = message => {
  Types.Log.make(message)->Log
}

type updateFn = (state, action) => state

let init = (fn: updateFn, initialState: state) => {
  let state = ref(initialState)

  let get = () => state.contents

  let set = (action: action) => {
    state := fn(state.contents, action)
    state.contents
  }

  (get, set)
}

let sortQueue = (tracks: array<Types.track>) => {
  tracks->Belt.SortArray.stableSortBy((a: Types.track, b: Types.track) =>
    if a.upvotes->Belt.Array.length == b.upvotes->Belt.Array.length {
      a.timestamp -. b.timestamp |> int_of_float
    } else {
      b.upvotes->Belt.Array.length - a.upvotes->Belt.Array.length
    }
  )
}

let update = (state: state, action: action) =>
  switch action {
  | Tick =>
    switch state.currentTrack {
    | Some(currentTrack) =>
      let now = Js.Date.now()
      let songEndsAt = currentTrack.timestamp +. float_of_int(currentTrack.track.track.durationMs)

      if now > songEndsAt {
        {
          ...state,
          currentTrack: None,
        }
      } else {
        {
          ...state,
          currentTrack: Some({
            ...currentTrack,
            position: now -. currentTrack.timestamp,
          }),
        }
      }
    | None => state
    }
  | Log(log) => {
      ...state,
      log: if state.log->Belt.Array.size > 100 {
        state.log->Belt.Array.concat([log])->Belt.Array.sliceToEnd(1)
      } else {
        state.log->Belt.Array.concat([log])
      },
    }
  | PlayTrack(track) => {
      ...state,
      currentTrack: Some({
        track: track,
        timestamp: Js.Date.now(),
        position: 0.0,
      }),
    }
  | AddUser(user) => {
      ...state,
      users: if state.users->Belt.Array.some(u => u.id == user.id) {
        state.users
      } else {
        state.users->Belt.Array.concat([user])
      },
    }
  | RemoveUser(user) => {
      ...state,
      users: state.users->Js.Array2.filter(u => u.id == user.id),
    }
  | AddTrack(track) => {
      ...state,
      tracks: if state.tracks->Belt.Array.some(t => t.track.id == track.track.id) {
        state.tracks
      } else {
        state.tracks->Belt.Array.concat([track])->sortQueue
      },
    }
  | RemoveTrack(trackId) => {
      ...state,
      tracks: state.tracks->Js.Array2.filter((track: Types.track) => track.track.id != trackId),
    }
  | VoteOnTrack(track, user) => {
      ...state,
      tracks: state.tracks->Belt.Array.map((t: Types.track) =>
        if t.track.id == track.track.id && t.upvotes->Belt.Array.some(u => u.id != user.id) {
          {
            ...track,
            upvotes: track.upvotes->Belt.Array.concat([user]),
          }
        } else {
          track
        }
      ) |> sortQueue,
    }
  }
