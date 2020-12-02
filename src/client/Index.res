module Index = {
  @react.component
  let make = () =>
    switch Utils.getToken() {
    | Some(token) => <> <App token /> </>
    | None => <div className="header"> <Login /> </div>
    }
}

ReactDOMRe.renderToElementWithId(<Index />, "app")
