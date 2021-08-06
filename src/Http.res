type t

@module("http") external createServer: Express.App.t => t = "createServer"
@send external listen: (t, int, unit => unit) => unit = "listen"
