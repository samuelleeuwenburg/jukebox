module Styles = {
    open Css;

    let error = style([
        color(Style.Colors.error),
        fontWeight(bold),
    ]);

    let trackContainer = style([
        display(`flex),
        flexWrap(wrap),
        flexDirection(row),
        width(pct(100.0)),
        padding2(px(10), px(0)),
        alignItems(center),
        borderBottom(px(1), `solid, Style.Colors.gray),
        selector("&:first-child", [
            borderTop(px(1), `solid, Style.Colors.gray)
        ])
    ]);

    let column = style([
        width(`calc(`sub, pct(25.0), px(35))),
        marginRight(px(20)),
        textOverflow(ellipsis),
        overflow(hidden),
        whiteSpace(nowrap),
        selector("&:last-child", [
            marginRight(zero)
        ])
    ]);

    let albumCover = style([
        width(px(40)),
        height(px(40)),
        backgroundColor(red),
        backgroundPosition(center),
        backgroundSize(cover),
        marginRight(px(40))
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
            <div className=Styles.column>
                {React.string(track.name)}
            </div>
            <div className=Styles.column>
                {React.string(track.name)}
            </div>
            <div className=Styles.column>
                {React.string(user.displayName)}
            </div>
            <div className=Styles.column>
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
        <ul>{tracks}</ul>
    })
    ->Belt.Option.getWithDefault(
        <p className=Styles.error>{React.string("ERROR: no queue found!")}</p>
    );


    <>
        <h2>{React.string("Next in queue")}</h2>
        {tracks}
    </>
};
