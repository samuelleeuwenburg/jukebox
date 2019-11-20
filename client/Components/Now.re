module Styles = {
    open Css;

    let currentTrackContainer = style([
        display(`flex),
        flexDirection(row),
        flexWrap(wrap),
        minHeight(px(170)),
        marginBottom(px(20)),
        media("(min-width: 640px)", [
            marginBottom(px(40)),
        ])
    ]);
    
    let trackContainer = style([
        flexGrow(1.0),
        display(`flex),
        flexDirection(column),
        position(relative),
        width(pct(100.0)),
        media("(min-width: 640px)", [
            width(`calc(`sub, pct(100.0), px(190))),
        ])
    ]);

    let currentTrack = style([
        fontWeight(bold),
        fontSize(px(16)),        
        textOverflow(ellipsis),
        overflow(hidden),
        whiteSpace(nowrap),
        media("(min-width: 640px)", [
            fontSize(px(22)),        
        ])
    ]);

    let currentArtist = style([
        fontSize(px(14)),
        color(Style.Colors.lightGray),
        textOverflow(ellipsis),
        overflow(hidden),
        whiteSpace(nowrap),
        marginBottom(px(20)),
        media("(min-width: 640px)", [
            fontSize(px(22)),        
            marginBottom(px(0))
        ])
    ])

    let albumCover = style([
        backgroundPosition(center),
        backgroundSize(cover),
        width(px(150)),
        height(px(150)),
        marginBottom(px(10)),
        margin3(zero, auto, px(10)),
        media("(min-width: 640px)", [
            width(px(170)),
            height(px(170)),
            margin4(zero, px(20), zero, zero),
        ])
    ]);
    
    let progressBar = style([
        width(pct(100.0)),
        backgroundColor(Style.Colors.gray),
        height(px(6)),
        media("(min-width: 640px)", [
            position(absolute),
            bottom(zero),
        ]) 
    ]);

    let progression = style([
        backgroundColor(Style.Colors.lightestGray),
        height(px(6)),
        transition("width", ~duration=100, ~timingFunction=`easeOut)
    ]);
}
[@react.component]
let make = (~dispatch, ~state: Types.state, ~token: string) => {

    state.currentTrack
    ->Belt.Option.map(currentTrack => {
        let fraction = float_of_int(currentTrack.position) /. float_of_int(currentTrack.track.durationMs);
        let percentage = floor(fraction *. 100.0);

        <div className=Styles.currentTrackContainer>
            <div 
            className=Styles.albumCover
            style=(ReactDOMRe.Style.make(~backgroundImage="url('"++currentTrack.track.imageUrl++"')", ()))
            >
            </div>

            <div className=Styles.trackContainer>
                <div className=Styles.currentTrack>
                    {React.string(currentTrack.track.name)}
                </div>
                <div className=Styles.currentArtist>
                    {React.string(currentTrack.track.name)}
                </div>

                <div className=Styles.progressBar>
                    <div 
                        className=Styles.progression 
                        style=(ReactDOMRe.Style.make(~width=string_of_float(percentage) ++ "%", ()))
                    ></div>
                </div>

            </div>
        </div>
    })
    ->Belt.Option.getWithDefault(React.null);
};

