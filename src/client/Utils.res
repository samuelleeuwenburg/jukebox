@bs.val external encodeURIComponent: string => string = ""

let goToUrl: string => unit = %bs.raw(
  ` function (url) {
        window.location.href = url;
    } `
)

let getToken = () => {
  open Webapi.Url.URLSearchParams
  open Belt.Option

  switch {
    open Dom.Storage
    localStorage |> getItem("access_token")
  } {
  | Some(token) => Some(token)
  | None =>
    let url = ReasonReactRouter.useUrl()
    (url.hash |> make |> get("access_token"))->flatMap(token => {
        {
          open Dom.Storage
          localStorage |> setItem("access_token", token)
        }
        Some(token)
      })
  }
}

let clearToken = () => {
  open Dom.Storage
  localStorage |> removeItem("access_token")
}
