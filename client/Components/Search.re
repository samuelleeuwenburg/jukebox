module Styles = {
    open Css;

    let searchContainer = style([
        maxWidth(px(500)),
        flexBasis(pct(100.0))
    ]);

    let inputContainer = style([
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
    ])

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

    let resultsContainer = style([
        position(absolute),
        zIndex(999),
        backgroundColor(Style.Colors.darkerGray),
        top(px(60)),
        padding2(px(20), px(20)),
        transform(translateX(px(-20))),
        width(pct(100.0)),
        overflow(auto),
        left(px(20)),
        maxHeight(`calc(`sub, vh(100.0), px(60))),
        media("(min-width: 640px)", [
            padding2(px(20), px(20)),
            width(px(580)),
            transform(translateX(px(-40))),
            left(initial)
        ])
    ])
}   

module Track = {
    type partialTrack = {
        id: string,
        name: string,
        uri: string,
        userId: string,
        imageUrl: string,
        durationMs: int,
    };

    [@react.component]
    let make = (~track: Spotify.track, ~token: string, ~user: Spotify.user, ~socket: IO.socket) => {
        let artist = List.hd(track.artists);

        let image = track.album.images
        |> List.find((image: Spotify.image) => image.width == 640);

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
            
            // dispatch(Types.ClearSearch);
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
    let clearSearch = React.useCallback0(() => {
        dispatch(Types.ClearSearch);
    });

    let getTracks = React.useCallback1(() => {
        Js.Promise.(
            Spotify.getTracks(token, state.query)
            |> then_(tracks => {
                dispatch(Types.UpdateResults(tracks));
                resolve(tracks)
            })
        ) |> ignore;
    }, [|state.query|]);

    let results = state.results
    ->Belt.Option.flatMap(results => {
        state.user->Belt.Option.map(user => (results, user));
    })
    ->Belt.Option.map(values => {
        open Spotify;
        let (results, user) = values;
        let tracks = results.items
        |> List.map(track => {
            <Track socket=state.socket token=token track=track key=track.uri user=user />
        })
        |> Array.of_list
        |> React.array;

        <ul className=Styles.resultsContainer>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(React.null);

    <div className=Styles.searchContainer>
        <div className=Styles.inputContainer>
            <input
                className=Styles.input
                placeholder="Search for tracks"
                value={state.query} 
                onChange={event => dispatch(Types.UpdateQuery(ReactEvent.Form.target(event)##value))}
            />
            <button onClick={_ => clearSearch()}>{React.string("clear")}</button>
            <button onClick={_ => getTracks()}>{React.string("search")}</button>
        </div>
        {results}
    </div>
};
