@val external encodeURIComponent: string => string = ""

let goToUrl: string => unit = %raw(` function (url) {
        window.location.href = url;
    } `)

let getToken = (urlHash: string) => {
  open Dom.Storage
  open Webapi.Url.URLSearchParams
  open Belt.Option

  switch localStorage |> getItem("access_token") {
  | Some(token) => Some(token)
  | None =>
    (urlHash |> make |> get("access_token"))
      ->flatMap(token => {
        localStorage |> setItem("access_token", token)
        Some(token)
      })
  }
}

let clearToken = () => {
  open Dom.Storage
  localStorage |> removeItem("access_token")
}
