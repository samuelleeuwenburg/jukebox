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

    let slicedArray = switch (Array.length(concatenatedQueries) > 10) {
    | true => Belt.(Array.slice(concatenatedQueries, ~offset=0, ~len=10));
    | false => concatenatedQueries;
    };

    switch (Js.Json.stringifyAny(slicedArray)) {
        | Some(stringifiedQueriesArray) => Dom.Storage.(localStorage |> setItem("recent-searches", stringifiedQueriesArray))
        | None => ()
    };
}
