module Path = {
    type pathT;
    [@bs.module "path"] [@bs.splice]
    external join : array(string) => string = "";
};

[@bs.val] external __dirname : string = "";

let app = Express.express();

let onListen = e => {
    switch (e) {
    | exception (Js.Exn.Error(e)) =>
        Js.log(e);
        Node.Process.exit(1);
    | _ => Js.log @@ "Listening at http://127.0.0.1:3000"
    };
};

Express.App.useOnPath(app, ~path="/") @@ {
    let publicFolder = Path.join([|__dirname, "../../public"|]);
    let options = Express.Static.defaultOptions();
    Express.Static.make(publicFolder, options) |> Express.Static.asMiddleware;
};

let server = Express.App.listen(app, ~port=3000, ~onListen, ());
