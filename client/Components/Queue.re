module Styles = {
    open Css;

    let error = style([
        color(Style.Colors.error),
        fontWeight(bold),
    ]);
    let tracksContainer = style([
        height(`calc(`sub, vh(100.0), px(440))),
        overflowX(auto),
        media("(min-width: 640px)", [
            height(`calc(`sub, vh(100.0), px(465))),
        ])
    ]);

    let trackContainer = style([
        display(`flex),
        flexWrap(wrap),
        flexDirection(row),
        width(pct(100.0)),
        alignItems(center),
        padding3(zero, zero, px(10)),
        media("(min-width: 640px)", [
            padding2(px(10), px(0)),
            borderBottom(px(1), `solid, Style.Colors.gray),
            selector("&:first-child", [
                borderTop(px(1), `solid, Style.Colors.gray)
            ]),
        ])
    ]);
    
    let trackInfoContainer = style([
        width(`calc(`sub, pct(100.0), px(165))),
        marginRight(px(20)),
        media("(min-width: 640px)", [
            width(`calc(`sub, pct(50.0), px(35))),
            marginRight(zero)
        ])
    ]);

    let column = style([
        textOverflow(ellipsis),
        overflow(hidden),
        whiteSpace(nowrap),
        fontSize(px(16)),
        selector("&:last-child", [
            marginRight(zero),
            color(Style.Colors.lightGray),
            media("(min-width: 640px)", [
                marginRight(px(20)),
                fontSize(px(18)),
                color(Style.Colors.lightestGray)
            ])
        ]),
        selector("&:first-child", [
            fontWeight(bold),
            color(Style.Colors.lightestGray),
            media("(min-width: 640px)", [
                fontWeight(normal),
            ])
        ]),
        media("(min-width: 640px)", [
            marginRight(px(20)),
            width(`calc(`sub, pct(50.0), px(35))),
            fontSize(px(18)),
            display(inlineBlock)
        ])
    ]);

    let queueTitle = style([
        fontSize(px(22)),
        marginBottom(px(10)),
        media("(min-width: 640px)", [
            fontSize(px(24)),
            marginBottom(px(20))
        ])
    ]);

    let addedByColumn = style([
        width(`calc(`sub, pct(25.0), px(35))),
        marginRight(px(20)),
        textOverflow(ellipsis),
        overflow(hidden),
        whiteSpace(nowrap),
        display(none),
        media("(min-width: 640px)", [
            display(block),
            color(Style.Colors.lightestGray)
        ])
    ]);

    let voteColumn = style([
        width(px(85)),
        media("(min-width: 640px)", [
            width(`calc(`sub, pct(25.0), px(35))),
        ])
    ]);


    let albumCover = style([
        width(px(40)),
        height(px(40)),
        backgroundColor(red),
        backgroundPosition(center),
        backgroundSize(cover),
        marginRight(px(20)),
        media("(min-width: 640px)", [
            marginRight(px(40)),
        ])
    ]);
};

module Track = {
    [@react.component]
    let make = (~socket: IO.socket, ~track: Bragi.track, ~user: Spotify.user) => {
        let voteTrack = React.useCallback0(() => {
            let data = Json.Encode.(object_([
                ("trackId", string(track.id)),
                ("userId", string(user.id)),
            ])); 

            Js.log("voting on track");
            Js.log(data);
            
            IO.socketEmit(socket, "vote", data) |> ignore;
            ();
        });

        <li className=Styles.trackContainer>
            <div 
                className=Styles.albumCover
                style=(ReactDOMRe.Style.make(~backgroundImage="url('"++track.imageUrl++"')", ()))
            >
            </div>
            <div className=Styles.trackInfoContainer>
                <div className=Styles.column>
                    {React.string(track.name)}
                </div>
                <div className=Styles.column>
                    {React.string(track.name)}
                </div>
            </div>
            <div className=Styles.addedByColumn>
                {React.string(user.displayName)}
            </div>
            <div className=Styles.voteColumn>
                <button onClick={_ => voteTrack()}>{React.string("vote")}</button>
                <strong>{React.string("+" ++ string_of_int(List.length(track.upvotes)) ++ " ")}</strong>
            </div>
        </li>
    }
};

[@react.component]
let make = (~dispatch, ~state: Types.state, ~token: string) => {
    let tracks = state.queue
    ->Belt.Option.flatMap(queue => {
        state.user->Belt.Option.map(user => (queue, user));
    })
    ->Belt.Option.map(values => {
        open Bragi;
        let (queue, user) = values;
        let tracks = queue.tracks
        |> List.map(track => {
            <Track key=track.id socket=state.socket track=track user=user />
        })
        |> Array.of_list
        |> React.array;
        <ul className=Styles.tracksContainer>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(
        <p className=Styles.error>{React.string("ERROR: no queue found!")}</p>
    );


    <>
        <h2 className=Styles.queueTitle>{React.string("Next in queue")}</h2>
        {tracks}
    </>
};
