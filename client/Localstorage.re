let getRecentSearchesFromStorage = () => {

    switch (Dom.Storage.(localStorage |> getItem("recent-searches"))) {
    | Some(queries) => {
        Json.parseOrRaise(queries) |> Json.Decode.(list(string));
    }
    | None => [];
    };
}

let setQueryToStorage = (query: string) => {
    let searchQueryArray = [|query|];
    let filteredList = List.filter(searchQuery => searchQuery !== query, getRecentSearchesFromStorage());
    let recentQueriesArray = Array.of_list(filteredList);
    let concatenatedQueries = Array.append(searchQueryArray, recentQueriesArray);

    switch (Js.Json.stringifyAny( concatenatedQueries)) {
        | Some(stringifiedQueriesArray) => Dom.Storage.(localStorage |> setItem("recent-searches", stringifiedQueriesArray))
        | None => ()
    };
}
