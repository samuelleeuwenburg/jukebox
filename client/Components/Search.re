open Debouncer;

module Styles = {
    open Css;

    let searchContainer = style([
        maxWidth(px(500)),
        flexBasis(pct(100.0)),
    ]);

    let inputContainer = style([
        position(relative)
    ]);

    let input = style([
    ]);

    let trackName = style([
        fontSize(px(18)),
        fontWeight(bold),
        textOverflow(ellipsis),
        overflow(hidden),
        whiteSpace(nowrap),
    ]);

    let artistName = style([
        fontSize(px(16)),
        color(Style.Colors.lightGray),
        textOverflow(ellipsis),
        overflow(hidden),
        whiteSpace(nowrap),
    ]);

    let trackInfoContainer = style([
        display(`flex),
        flexDirection(column),
        justifyContent(center),
        width(`calc(`sub, pct(100.0), px(80)))
    ]);

    let trackContainer = style([
        display(`flex),
        flexWrap(wrap),
        flexDirection(row),
        marginBottom(px(20)),
        cursor(`pointer),
        selector("&:hover", [
            backgroundColor(Style.Colors.darkGray)
        ])
    ]);

    let albumCover = style ([
        width(px(60)),
        height(px(60)),
        backgroundPosition(center),
        backgroundSize(cover),
        marginRight(px(20))
    ]);

    let searchButtonContainer = style([
        position(absolute),
        right(zero),
        top(zero),
        cursor(`pointer)
    ]);

    let resultsContainer = style([
        position(absolute),
        zIndex(999),
        backgroundColor(Style.Colors.darkerGray),
        top(px(60)),
        padding(px(20)),
        transform(translateX(px(-20))),
        width(pct(100.0)),
        overflow(auto),
        left(px(20)),
        maxHeight(`calc(`sub, vh(100.0), px(60))),
        media("(min-width: 640px)", [
            padding2(px(20), px(40)),
            width(px(580)),
            transform(translateX(px(-40))),
            left(initial)
        ])
    ])
}   

module Track = {
    [@react.component]
    let make = (~dispatch, ~track: Spotify.track, ~token: string, ~user: Spotify.user, ~socket: IO.socket) => {
        let artist = List.hd(track.artists);
        let image = track.album.images
        |> List.sort((a: Spotify.image, b: Spotify.image) => b.width - a.width)
        |> List.hd;

        let addTrack = React.useCallback0(() => {
            let data = Json.Encode.(object_([
                ("id", string(track.id)),
                ("name", string(track.name)),
                ("uri", string(track.uri)),
                ("userId", string(user.id)),
                ("imageUrl", string(image.url)),
                ("durationMs", int(track.durationMs)),
            ])); 

            Js.log("adding track");
            Js.log(data);
            
            dispatch(Types.ClearSearch);
            IO.socketEmit(socket, "addTrack", data) |> ignore;
        });

        <li className=Styles.trackContainer onClick={_ => addTrack()}>
            <div 
                className=Styles.albumCover
                style=(ReactDOMRe.Style.make(~backgroundImage="url('"++image.url++"')", ()))
            >
            </div>
            <div className=Styles.trackInfoContainer>
                <div className=Styles.trackName>
                    {React.string(track.name)}
                </div>
                <div className=Styles.artistName>
                    {React.string(artist.name)}
                </div>
            </div>
        </li>
    };
};

[@react.component]
let make = (~dispatch, ~token: string, ~state: Types.state) => {
    let (query, setQuery) = React.useState(() => "");

    let getTracks(query) = {
        Js.log2(query, "get tracks query")
        Js.Promise.(
            Spotify.getTracks(token, query)
            |> then_(tracks => {
                dispatch(Types.UpdateResults(tracks));
                resolve(tracks)
            })
        ) |> ignore;
    };
    
    let results = state.results
    ->Belt.Option.flatMap(results => {
        state.user->Belt.Option.map(user => (results, user));
    })
    ->Belt.Option.map(values => {
        open Spotify;
        let (results, user) = values;
        let tracks = results.items
        |> List.map(track => {
            <Track
                key=track.uri
                socket=state.socket
                token=token
                track=track
                user=user
                dispatch=dispatch
            />
        })
        |> Array.of_list
        |> React.array;

        <ul className=Styles.resultsContainer>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(React.null);

    // let debouncedGetTracks = Debouncer.make(~wait=1000, (query) => getTracks(query));
    let debouncedGetTracks = React.useRef(Debouncer.make(~wait=1000, (query) => {
        getTracks(query)
    }));

    let onChanges(value) =  {
        dispatch(Types.UpdateQuery(value));
        React.Ref.current(debouncedGetTracks, value);
    };

    <div className=Styles.searchContainer>
        <div className=Styles.inputContainer>
            <input
                className=Styles.input
                placeholder="Search for tracks"
                value={state.query}
                onChange={event => onChanges(ReactEvent.Form.target(event)##value)}
            />
            <span className=Styles.searchButtonContainer>
                <svg width="15.761" height="15.761" viewBox="0 0 15.761 15.761">
                    <path 
                        id="iconfinder_67_111124" 
                        d="M61.415,58.451a1.39,1.39,0,0,1-1.965,1.968L55.427,56.4a6.131,6.131,0,1,1,1.968-1.968Zm-4.847-7.257a4.378,4.378,0,1,0-4.378,4.378A4.379,4.379,0,0,0,56.568,51.194Z" 
                        transform="translate(-46.062 -45.065)" 
                        fill="#858585" 
                        fillRule="evenodd"
                    />
                </svg>
            </span>
        </div>
        {results}
    </div>
};
