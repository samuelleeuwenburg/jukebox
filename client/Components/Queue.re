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
        width(`calc(`sub, pct(100.0), px(119))),
        marginRight(px(20)),
        media("(min-width: 640px)", [
            width(`calc(`sub, pct(66.0), px(70))),
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

    let voteContainer = style([
        cursor(`pointer)
    ]);

    let addedByColumn = style([
        width(`calc(`sub, pct(33.0), px(83))),
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

    let voteIcon = style([
        marginRight(px(10))
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
                <div className=Styles.voteContainer onClick={_ => voteTrack()}>
                    <span className=Styles.voteIcon>
                        <svg width="19.575" height="18.993" viewBox="0 0 19.575 18.993">
                            <path 
                                id="Path_5" 
                                d="M12.37,84.63a.6.6,0,1,0,0-1.2c-.007,0-.011,0-.018,0l-1.429,0a.761.761,0,0,0-.1-.007.821.821,0,0,0-.815.826L10,94.171a.811.811,0,0,0,.815.815.839.839,0,0,0,.13,0H12.37v0a.571.571,0,0,0,0-1.142V93.83H11.2l.034-9.2,1.131,0Zm16.843-.858a2.126,2.126,0,0,0-1.859-1.041.743.743,0,0,0-.123-.009l-4.7-.016a9.434,9.434,0,0,0,.52-2.959,8.867,8.867,0,0,0-.206-1.888h-.011A2.381,2.381,0,0,0,20.522,76a2.258,2.258,0,0,0-2.184,2.428c0,.074-.007.146,0,.217a5.033,5.033,0,0,1-4.488,4.746v1.256l-.018,5.084v5.257h.244l11.438,0,.2-.007a1.742,1.742,0,0,0,1.093-.37,2.412,2.412,0,0,0,.858-.965.829.829,0,0,0,.116-.255l1.763-7.877a.841.841,0,0,0,.025-.278,2.45,2.45,0,0,0-.356-1.469Zm-.748,1.209-1.9,8.412h0a.763.763,0,0,1-.6.468.827.827,0,0,0-.105,0l-10.912-.013,0-9.319c2.043-.921,3.541-1.823,4.314-3.973,0,0,0,0,0,0a6.33,6.33,0,0,0,.2-.759,7.648,7.648,0,0,0,.121-1.33,1.029,1.029,0,0,1,1.015-1.212,1.443,1.443,0,0,1,1.149,1.2,7.613,7.613,0,0,1,.13,1.308,6.154,6.154,0,0,1-.108,1.3h-.011a7.087,7.087,0,0,1-.7,1.989l.009.009a.826.826,0,0,0-.085.365c0,.457.437.5.887.5l5.463.007.336.011v0a.783.783,0,0,1,.712.376.809.809,0,0,1,.081.663ZM14.076,94.991h.007s.009,0-.007,0-.011,0-.007,0Z" 
                                transform="translate(-10 -76)" 
                                fill="#b3b3b3"
                            />
                        </svg>
                    </span>
                    <div className=Styles.votes>{React.string(string_of_int(List.length(track.upvotes)))}</div>
                </div>
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
