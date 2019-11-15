module Index = {
    [@react.component]
    let make = () => {
        switch (Utils.getToken()) {
        | Some(token) => {
                <>
                    <Logout />
                    <App token=token />
                </>
            }
        | None => {
                <Login />
            }
        };
    };
};

ReactDOMRe.renderToElementWithId(<Index />, "app");
