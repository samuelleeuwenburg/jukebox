module Index = {
    [@react.component]
    let make = () => {
        <App />
    };
};

ReactDOMRe.renderToElementWithId(<Index />, "app");
