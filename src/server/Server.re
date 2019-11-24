[@bs.val] external __dirname : string = "";

module Http = {
    type t;
    [@bs.module "http"] external createServer: Express.App.t => t = "createServer";
    [@bs.send] external listen: (t, int, unit => unit) => unit = "";
};

module IO = {
    type t;
    type socket;
    type options = Js.Json.t;
    [@bs.module] external io: (Http.t, options) => t = "socket.io";
    [@bs.send] external on: (t, string, (socket => unit)) => unit = "on";
    [@bs.send] external emit: (t, string, 'a) => unit = "emit";

    module Socket = {
        [@bs.send] external on: (socket, string, (Js.Json.t => unit)) => unit = "on";
        [@bs.send] external emit: (socket, string, 'a) => unit = "emit";
    };
}

module Path = {
    type pathT;
    [@bs.module "path"] [@bs.splice]
    external join : array(string) => string = "";
};

module State = {
    type state = {
        tracks: list(Bragi.track),
        currentTrack: option(Bragi.currentTrack),
    };

    type action = 
        | AddTrack(Bragi.track)
        | RemoveTrack(string)
        | Tick;

    type updateFn = (state, action) => state;

    let init = (fn: updateFn, initialState: state) => {
        let state = ref(initialState);

        let get = () => state^;

        let set = (action: action) => {
            state := fn(state^, action);
            state;
        };

        (get, set);
    };

    let sortQueue = (tracks: list(Bragi.track)) => {
        List.(
            tracks |> sort((a: Bragi.track, b: Bragi.track) => {
                if (a.upvotes->length == b.upvotes->length) {
                    a.timestamp - b.timestamp;
                } else {
                    b.upvotes->length - a.upvotes->length;
                };
            })
        );
    };

    let update = (state: state, action: action) => {
        switch (action) {
        | AddTrack(track) => {
            {
                ...state,
                tracks: [track, ...state.tracks]->sortQueue
            }
        }
        | RemoveTrack(trackId) => {
            {
                ...state,
                tracks: state.tracks 
                |> List.filter((track: Bragi.track) => track.id == trackId)
            }
        }
        };
    }

    let initialState = { tracks: [], currentTrack: None };
};

let (getState, dispatch) = State.init(State.update, State.initialState);
let app = Express.express();
let http = Http.createServer(app);
let io = IO.io(http, Json.Encode.object_([("path", Json.Encode.string("/socket.io"))]));

IO.on(io, "connect", (socket) => {
    Js.log("connection received");
    IO.Socket.on(socket, "vote", json => {
        Js.log("received vote");
    });

    IO.Socket.on(socket, "addTrack", json => {
        let track = json |> Bragi.Decode.track;
        dispatch(AddTrack(track));
        Js.log2("adding track ->", track);
        ();
    });

    IO.Socket.on(socket, "getQueue", _ => {
        Js.log("get queue");

        let state = getState();
        let json = Json.Encode.(object_([
            ("tracks", state.tracks |> list(Bragi.Encode.track)),
            ("currentTrack", nullable(Bragi.Encode.currentTrack, state.currentTrack))
        ]));

        IO.Socket.emit(socket, "newQueue", json);
    });
});

Express.App.useOnPath(app, ~path="/") @@ {
    let publicFolder = Path.join([|__dirname, "../../public"|]);
    let options = Express.Static.defaultOptions();
    Express.Static.make(publicFolder, options) |> Express.Static.asMiddleware;
};

Http.listen(http, 3000, () => {
    Js.log("jukeboxing on port 3000!");
});
