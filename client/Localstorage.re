[@bs.val] external jsonParse: string => 'a = "JSON.parse"

let getRecentSearchesFromStorage = () => {
    switch (Dom.Storage.(localStorage |> getItem("recent-searches"))) {
    | Some(queries) => jsonParse(queries)
    | None => [];
    };
}

let setQueryToStorage = (query) => {
    let searchQueryArray = [|query|];
    let recentQueriesArray = Array.of_list(getRecentSearchesFromStorage());
    let concatenatedQueries = Array.append(searchQueryArray, recentQueriesArray);

    switch (Js.Json.stringifyAny(concatenatedQueries)) {
        | Some(stringifiedQueriesArray) => Dom.Storage.(localStorage |> setItem("recent-searches", stringifiedQueriesArray))
        | None => ()
    };
}
