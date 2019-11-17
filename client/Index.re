module Index = {
    [@react.component]
    let make = () => {
        switch (Utils.getToken()) {
        | Some(token) => {
            <>
                <div className="header">
                    <Logout />
                </div>
                <App token=token />
            </>
        }
        | None => {
            <div className="header">
                <Login />
            </div>
            }
        };
    };
};

ReactDOMRe.renderToElementWithId(<Index />, "app");
