module Hash = {
  let adjList = [
    "running",
    "fighting",
    "crying",
    "levitating",
    "meditating",
    "sleeping",
    "snoring",
    "skating",
    "rollerblading",
    "surfing",
    "gold",
    "silver",
    "walking",
    "flying",
    "jumping",
    "edgy",
    "angsty",
    "happy",
    "drunk",
    "useful",
    "medical",
    "expensive",
    "impossible",
    "typical",
    "unusual",
    "reasonable",
    "lucky",
    "weak",
    "suspicious",
    "complex",
    "slow",
    "round",
    "square",
    "illegal",
    "legal",
    "plain",
    "basic",
    "habitual",
    "abnormal",
    "allergic",
    "cumbersome",
    "colossal",
    "cynical",
    "disastrous",
    "divergent",
    "fearless",
    "grotesque",
    "grandiose",
    "holistic",
    "icky",
    "infamous",
    "jazzy",
    "jaded",
    "lavish",
    "lewd",
    "omniscient",
    "perpetual",
    "psychedelic",
    "questionable",
    "quirky",
    "quaint",
    "sassy",
    "steadfast",
    "ubiquitous",
  ]

  let nounList = [
    "table",
    "chair",
    "giraffe",
    "fish",
    "potato",
    "tomato",
    "bear",
    "towel",
    "car",
    "cat",
    "mouse",
    "dog",
    "bag",
    "lamp",
    "flower",
    "plant",
    "walkman",
    "sugar",
    "bottle",
    "card",
    "fez",
    "fiasco",
    "lizzard",
    "event",
    "fox",
    "donkey",
    "egg",
    "toast",
    "history",
    "world",
    "year",
    "science",
    "failure",
    "saviour",
    "hero",
    "villain",
    "nature",
    "fact",
    "country",
    "analysis",
    "dealer",
    "customer",
    "solution",
    "atmosphere",
    "mode",
    "river",
    "agent",
    "shirt",
    "letter",
    "spell",
    "border",
  ]

  let colorList = [
    "white",
    "gainsboro",
    "silver",
    "whitesmoke",
    "lightgray",
    "lightcoral",
    "rosybrown",
    "indianred",
    "red",
    "snow",
    "mistyrose",
    "salmon",
    "orangered",
    "chocolate",
    "brown",
    "seashell",
    "peachpuff",
    "tomato",
    "darkorange",
    "peru",
    "firebrick",
    "linen",
    "bisque",
    "darksalmon",
    "orange",
    "goldenrod",
    "sienna",
    "oldlace",
    "antiquewhite",
    "coral",
    "gold",
    "limegreen",
    "saddlebrown",
    "floralwhite",
    "navajowhite",
    "lightsalmon",
    "darkkhaki",
    "lime",
    "darkgoldenrod",
    "cornsilk",
    "blanchedalmond",
    "sandybrown",
    "yellow",
    "mediumseagreen",
    "olivedrab",
    "ivory",
    "papayawhip",
    "burlywood",
    "yellowgreen",
    "springgreen",
    "seagreen",
    "beige",
    "moccasin",
    "chartreuse",
    "mediumspringgreen",
    "lightseagreen",
    "lightyellow",
    "wheat",
    "khaki",
    "lawngreen",
    "aqua",
    "darkturquoise",
    "lightgoldenrodyellow",
    "lemonchiffon",
    "greenyellow",
    "darkseagreen",
    "cyan",
    "deepskyblue",
    "honeydew",
    "palegoldenrod",
    "lightgreen",
    "mediumaquamarine",
    "cadetblue",
    "steelblue",
    "mintcream",
    "palegreen",
    "skyblue",
    "turquoise",
    "dodgerblue",
    "blue",
    "azure",
    "aquamarine",
    "lightskyblue",
    "mediumturquoise",
    "blueviolet",
    "lightcyan",
    "paleturquoise",
    "lightsteelblue",
    "cornflowerblue",
    "darkorchid",
    "aliceblue",
    "powderblue",
    "thistle",
    "mediumslateblue",
    "royalblue",
    "fuchsia",
    "ghostwhite",
    "lightblue",
    "plum",
    "mediumpurple",
    "slateblue",
    "magenta",
    "lavender",
    "pink",
    "violet",
    "orchid",
    "mediumorchid",
    "mediumvioletred",
    "lavenderblush",
    "lightpink",
    "hotpink",
    "palevioletred",
    "deeppink",
    "crimson",
    "darkmagenta",
    "rebeccapurple",
  ]

  let make = (input, intoArray) => {
    let num =
      input
      ->Js.String2.castToArrayLike
      ->Js.Array2.from
      ->Belt.Array.map(Js.String2.charCodeAt(_, 0))
      ->Belt.Array.reduce(1.0, (sum, x) => sum +. x)

    let pos = mod(num->Belt.Float.toInt, intoArray->Belt.Array.length)->Js.Math.abs_int

    intoArray[pos]
  }
}

let fromSpotifyUser = (user: Spotify.user): Types.user => {
  let input = user.displayName
  let length = input->Js.String2.length

  let adj = input->Js.String2.slice(~from=0, ~to_=length / 2)->Hash.make(Hash.adjList)

  let noun = input->Js.String2.slice(~from=length / 2, ~to_=length)->Hash.make(Hash.nounList)

  let color = input->Hash.make(Hash.colorList)

  {
    id: `${adj} ${noun}`,
    color: color,
  }
}

module Conn = {
  let handle = (io, socket, _getState, dispatch) => {
    let userRef = ref(None)

    socket->SocketIO.on("disconnect", () => {
      switch userRef.contents {
      | Some(user) => {
          ServerState.RemoveUser(user)->dispatch->ignore
          let state: ServerState.state = ServerState.log(Types.Log.UserLeft(user))->dispatch
          io->SocketIO.Server.emit(Types.Socket.SendUserList, state.users)
          io->SocketIO.Server.emit(Types.Socket.SendLog, state.log)
        }
      | None => ()
      }
    })

    socket->SocketIO.on(Types.Socket.RequestUser, (user: Spotify.user) => {
      let user = user->fromSpotifyUser
      userRef := Some(user)

      ServerState.AddUser(user)->dispatch->ignore
      let state: ServerState.state = ServerState.log(Types.Log.UserJoined(user))->dispatch

      socket->SocketIO.emit(Types.Socket.SendUser, user)

      io->SocketIO.Server.emit(Types.Socket.SendUserList, state.users)
      io->SocketIO.Server.emit(Types.Socket.SendLog, state.log)
    })
  }
}
