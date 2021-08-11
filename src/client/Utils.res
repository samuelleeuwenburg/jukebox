@scope(("window", "location")) @val external origin: string = "origin"
@scope(("window", "history")) @val external pushState: ('a, string, string) => unit = "pushState"

@val external encodeURIComponent: string => string = "encodeURIComponent"

module URLSearchParams = {
  type t
  @new external make: string => t = "URLSearchParams"

  @send @return(nullable) external get: (t, string) => option<string> = "get"
}

let goToUrl: string => unit = %raw(` function (url) {
        window.location.href = url;
    } `)
