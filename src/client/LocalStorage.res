let getRecentSearchesFromStorage = () =>
  switch {
    open Dom.Storage
    localStorage |> getItem("recent-searches")
  } {
  | Some(queries) =>
    Json.parseOrRaise(queries) |> {
      open Json.Decode
      list(string)
    }

  | None => list{}
  }

let setQueryToStorage = (query: string) => {
  let searchQueryArray = [query]
  let filteredList = List.filter(
    searchQuery => searchQuery !== query,
    getRecentSearchesFromStorage(),
  )
  let recentQueriesArray = Array.of_list(filteredList)
  let concatenatedQueries = Array.append(searchQueryArray, recentQueriesArray)

  let slicedArray =
    Array.length(concatenatedQueries) > 10
      ? {
          open Belt
          Array.slice(concatenatedQueries, ~offset=0, ~len=10)
        }
      : concatenatedQueries

  switch Js.Json.stringifyAny(slicedArray) {
  | Some(stringifiedQueriesArray) =>
    open Dom.Storage
    localStorage |> setItem("recent-searches", stringifiedQueriesArray)
  | None => ()
  }
}
