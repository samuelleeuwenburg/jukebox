module Styles = {
    open Css;

    let error = style([
        color(Style.Colors.error),
        fontWeight(bold),
    ]);
    let tracksContainer = style([
        height(`calc(`sub, vh(100.0), px(450))),
        overflowX(auto),
        media("(min-width: 640px)", [
            height(`calc(`sub, vh(100.0), px(440))),
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
        width(`calc(`sub, pct(100.0), px(119))),
        marginRight(px(20)),
        media("(min-width: 640px)", [
            width(`calc(`sub, pct(66.0), px(92))),
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
            width(`calc(`sub, pct(50.0), px(20))),
            fontSize(px(18)),
            display(inlineBlock)
        ])
    ]);

    let queueTitle = style([
        fontSize(px(20)),
        marginBottom(px(10)),
        media("(min-width: 640px)", [
            fontSize(px(24)),
            marginBottom(px(20))
        ])
    ]);

    let voteContainer = (hasVoted) => style([
        cursor(hasVoted ? `default : `pointer),
        pointerEvents(hasVoted ? `none : `auto),
        selector("& path", [
            SVG.fill(hasVoted ? Style.Colors.lightestGray : `transparent),
        ]),
    ]);

    let addedByColumn = style([
        width(`calc(`sub, pct(33.0), px(61))),
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
        media("(min-width: 640px)", [
            marginRight(px(20))
        ])
    ]);

    let voteIcon =  style([
        marginRight(px(10)),
        selector("&:hover path", [
            SVG.fill(Style.Colors.lightestGray)
        ])
    ]);

    let votes = style([
        display(inlineBlock),
        fontWeight(bold)
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
        let hasVoted = Belt.List.getBy(track.upvotes, vote => vote === user.id)
        ->Belt.Option.isSome

        let voteTrack = React.useCallback1(() => {
            switch (hasVoted) {
                | true => ()
                | false => {
                    let data = Json.Encode.(object_([
                        ("trackId", string(track.id)),
                        ("userId", string(user.id)),
                    ])); 

                    Js.log("voting on track");
                    Js.log(data);
                    
                    IO.socketEmit(socket, "vote", data) |> ignore;
                    ();
                }
            }
        }, [|hasVoted|]);

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
                    {React.string(track.artist)}
                </div>
            </div>
            <div className=Styles.addedByColumn>
                {React.string(track.userId)}
            </div>
            <div className=Styles.voteColumn>
                <div className=Styles.voteContainer(hasVoted) onClick={_ => voteTrack()}>
                    <span className=Styles.voteIcon>
                        <svg width="19.775" height="18.874" viewBox="0 0 19.775 18.874">
                            <g transform="translate(-1328.764 -398.263)">
                                <path 
                                d="M1362.145,419.369a6.177,6.177,0,0,0,3.835-2.661,5.423,5.423,0,0,0,.987-3.6s-.2-.822,1.5-1.277,1.806,1.916,1.806,1.916a7.648,7.648,0,0,1,0,1.721c-.126.4-.62,2.454-.62,2.454h5.373s2.343.1,1.964,1.513-1.964,8.7-1.964,8.7a1.515,1.515,0,0,1-1.495,1.495H1362V418.7" 
                                transform="translate(-29 -13)" 
                                fill="none" 
                                stroke="#b3b3b3" 
                                strokeWidth="1"/>
                                <path 
                                d="M1360.094,1577.225h-3.831v10.444h9.073" 
                                transform="translate(-27 -1171.032)" 
                                fill="none" 
                                stroke="#b3b3b3" 
                                strokeWidth="1"/>
                            </g>
                        </svg>
                    </span>
                    <div className=Styles.votes>{React.string(string_of_int(List.length(track.upvotes)))}</div>
                </div>
            </div>
        </li>
    }
};

[@react.component]
let make = (~dispatch, ~state: Types.state) => {
    state.queue
    ->Belt.Option.flatMap(tracks => {
        state.user->Belt.Option.map(user => (tracks, user));
    })
    ->Belt.Option.map(values => {
        open Bragi;
        let (tracks, user) = values;

        let trackEls = tracks
        |> List.map(track => {
            <Track key=track.id socket=state.socket track=track user=user />
        })
        |> Array.of_list
        |> React.array;

        let title = if (List.length(tracks) == 0) {
            <h2 className=Styles.queueTitle>{React.string("Queue is empty")}</h2>
        } else {
            <h2 className=Styles.queueTitle>{React.string("Next in queue")}</h2>
        };

        <>
            {title}
            <ul className=Styles.tracksContainer>{trackEls}</ul>
        </>
    })
    ->Belt.Option.getWithDefault(
        <p className=Styles.error>{React.string("ERROR: no queue found!")}</p>
    );
};
