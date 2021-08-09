@scope(("window", "location")) @val external origin: string = "origin"

@val external encodeURIComponent: string => string = "encodeURIComponent"

module URLSearchParams = {
  type t
  @new external make: string => t = "URLSearchParams"

  @nullable @send external get: (t, string) => option<string> = "get"
}

let goToUrl: string => unit = %raw(` function (url) {
        window.location.href = url;
    } `)
