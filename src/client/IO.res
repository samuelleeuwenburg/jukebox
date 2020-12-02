type socket

let getSocket: (string, string) => socket = %bs.raw(
  ` function (url, path) {
        return io(url, { path: path });
    } `
)

let socketOn = %bs.raw(
  ` function (socket, event, callback) {
        socket.on(event, callback);
    } `
)

let socketOff = %bs.raw(
  ` function (socket, event, callback) {
        socket.off(event, callback);
    } `
)

let socketEmit = %bs.raw(
  ` function(socket, event, data) {
        socket.emit(event, data);
    } `
)
