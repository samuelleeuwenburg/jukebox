type socket;

let getSocket: string => socket = [%bs.raw
    {| function (url) {
        return io(url);
    } |}
];

let socketOn = [%bs.raw
    {| function (socket, event, callback) {
        socket.on(event, callback);
    } |}
];
