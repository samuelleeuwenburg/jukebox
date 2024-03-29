type state = {
  query: string,
  results: option<Spotify.response<Spotify.track>>,
  player: option<Spotify.player>,
  devices: option<array<Spotify.device>>,
  spotifyUser: option<Spotify.user>,
  user: option<Types.user>,
  queue: option<array<Types.track>>,
  currentTrack: option<Types.currentTrack>,
  userList: option<array<Types.user>>,
  log: option<array<Types.Log.t>>,
}

type action =
  | NoOp
  | Tick
  | UpdateLog(array<Types.Log.t>)
  | UpdateQuery(string)
  | UpdateResults(Spotify.response<Spotify.track>)
  | UpdatePlayer(Spotify.player)
  | UpdateDevices(array<Spotify.device>)
  | UpdateSpotifyUser(Spotify.user)
  | UpdateUser(Types.user)
  | UpdateQueue(array<Types.track>)
  | UpdateCurrentTrack(Types.currentTrack)
  | UpdateUserList(array<Types.user>)
  | HandleNow(Types.now)
  | ClearSearch
  | Error

let initialState: state = {
  query: "",
  results: None,
  devices: None,
  player: None,
  spotifyUser: None,
  user: None,
  queue: None,
  currentTrack: None,
  userList: None,
  log: None,
}

let rec reducer = (state: state, action: action) => {
  switch action {
  | NoOp => state
  | Tick =>
    state.currentTrack
    ->Belt.Option.map(currentTrack => {
      let position = Js.Date.now() -. currentTrack.timestamp
      if position > float_of_int(currentTrack.track.track.durationMs) {
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
  | UpdateLog(log) => {...state, log: Some(log)}
  | UpdateQuery(query) => {...state, query: query}
  | UpdateDevices(devices) => {...state, devices: Some(devices)}
  | UpdatePlayer(player) => {...state, player: Some(player)}
  | UpdateSpotifyUser(user) => {...state, spotifyUser: Some(user)}
  | UpdateUser(user) => {...state, user: Some(user)}
  | UpdateUserList(userList) => {...state, userList: Some(userList)}
  | UpdateQueue(queue) => {...state, queue: Some(queue)}
  | UpdateResults(response) => {...state, results: Some(response)}
  | ClearSearch => {...state, query: "", results: None}
  | UpdateCurrentTrack(currentTrack) => {
      ...state,
      currentTrack: Some({
        ...currentTrack,
        timestamp: Js.Date.now() -. currentTrack.position,
      }),
    }
  | HandleNow(now) => {
      let addTracks =
        now.tracks->Belt.Option.map(t => UpdateQueue(t))->Belt.Option.getWithDefault(NoOp)

      let addCurrentTrack =
        now.currentTrack
        ->Belt.Option.map(t => UpdateCurrentTrack(t))
        ->Belt.Option.getWithDefault(NoOp)

      state->reducer(addTracks)->reducer(addCurrentTrack)
    }
  | Error => state
  }
}
