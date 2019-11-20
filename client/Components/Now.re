module Styles = {
    open Css;

    let currentTrackContainer = style([
        display(`flex),
        flexDirection(row),
        flexWrap(wrap),
        minHeight(px(170)),
        marginBottom(px(40))
    ]);
    
    let trackContainer = style([
        flexGrow(1.0),
        display(`flex),
        flexDirection(column),
        position(relative)
    ]);

    let currentTrack = style([
        fontWeight(bold),
        fontSize(px(22))
    ]);

    let currentArtist = style([
        fontSize(px(20)),
        color(Style.Colors.lightGray)
    ])

    let albumCover = style([
        backgroundPosition(center),
        backgroundSize(cover),
        width(px(170)),
        height(px(170)),
        marginRight(px(20))
        
    ]);
    
    let progressBar = style([
        width(pct(100.0)),
        backgroundColor(Style.Colors.gray),
        height(px(6)),
        position(absolute),
        bottom(zero)
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

