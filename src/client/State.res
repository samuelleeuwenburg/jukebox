let initialState: Types.state = {
  token: None,
  query: "",
  results: None,
  player: None,
  spotifyUser: None,
  user: None,
  queue: None,
  currentTrack: None,
  userList: None,
}

let rec reducer = (state: Types.state, action: Types.action) => {
  switch action {
  | Types.NoOp => state
  | Types.Tick =>
    state.currentTrack
    ->Belt.Option.map(currentTrack => {
      let position = Js.Date.now() -. currentTrack.timestamp
      if position > float_of_int(currentTrack.track.durationMs) {
        {
          ...state,
          currentTrack: None,
        }
      } else {
        {
          ...state,
          currentTrack: Some({...currentTrack, position: position}),
        }
      }
    })
    ->Belt.Option.getWithDefault(state)
  | Types.UpdateToken(token) => {...state, token: token}
  | Types.UpdateQuery(query) => {...state, query: query}
  | Types.UpdatePlayer(player) => {...state, player: Some(player)}
  | Types.UpdateSpotifyUser(user) => {...state, spotifyUser: Some(user)}
  | Types.UpdateUser(user) => {...state, user: Some(user)}
  | Types.UpdateUserList(userList) => {...state, userList: Some(userList)}
  | Types.UpdateQueue(queue) => {...state, queue: Some(queue)}
  | Types.UpdateResults(response) => {...state, results: Some(response)}
  | Types.ClearSearch => {...state, query: "", results: None}
  | Types.UpdateCurrentTrack(currentTrack) => {
      ...state,
      currentTrack: Some({
        ...currentTrack,
        timestamp: Js.Date.now() -. currentTrack.position,
      }),
    }
  | Types.HandleNow(now) => {
      let addTracks =
        now.tracks
        ->Belt.Option.map(t => Types.UpdateQueue(t))
        ->Belt.Option.getWithDefault(Types.NoOp)

      let addCurrentTrack =
        now.currentTrack
        ->Belt.Option.map(t => Types.UpdateCurrentTrack(t))
        ->Belt.Option.getWithDefault(Types.NoOp)

      state->reducer(addTracks)->reducer(addCurrentTrack)
    }
  | Types.Error => state
  }
}
