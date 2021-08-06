module Styles = {
  open Css

  let currentTrackContainer = style(list{
    display(#flex),
    flexDirection(row),
    flexWrap(wrap),
    minHeight(px(170)),
    marginBottom(px(20)),
    media("(min-width: 640px)", list{marginBottom(px(40))}),
  })

  let trackContainer = style(list{
    flexGrow(1.0),
    display(#flex),
    flexDirection(column),
    position(relative),
    width(pct(100.0)),
    media("(min-width: 640px)", list{width(#calc(#sub, pct(100.0), px(190)))}),
  })

  let currentTrack = style(list{
    fontWeight(bold),
    fontSize(px(16)),
    textOverflow(ellipsis),
    overflow(hidden),
    whiteSpace(nowrap),
    media("(min-width: 640px)", list{fontSize(px(22))}),
  })

  let currentArtist = style(list{
    fontSize(px(14)),
    color(Style.Colors.lightGray),
    textOverflow(ellipsis),
    overflow(hidden),
    whiteSpace(nowrap),
    marginBottom(px(20)),
    media("(min-width: 640px)", list{fontSize(px(22)), marginBottom(px(0))}),
  })

  let albumCover = style(list{
    backgroundPosition(center),
    backgroundSize(cover),
    width(px(150)),
    height(px(150)),
    marginBottom(px(10)),
    margin3(~top=zero, ~h=auto, ~bottom=px(10)),
    media(
      "(min-width: 640px)",
      list{
        width(px(170)),
        height(px(170)),
        margin4(~top=zero, ~right=px(20), ~bottom=zero, ~left=zero),
      },
    ),
  })

  let progressBar = style(list{
    width(pct(100.0)),
    backgroundColor(Style.Colors.gray),
    height(px(6)),
    marginBottom(px(20)),
    media("(min-width: 640px)", list{position(absolute), bottom(zero), marginBottom(zero)}),
  })

  let progression = style(list{
    backgroundColor(Style.Colors.lightestGray),
    height(px(6)),
    transition("width", ~duration=200, ~timingFunction=#linear),
  })

  let devicesContainer = style(list{
    display(#flex),
    flexWrap(wrap),
    flexDirection(row),
    justifyContent(#flexEnd),
    order(1),
    height(px(20)),
    media("(min-width: 640px", list{order(0), marginBottom(zero)}),
  })

  let deviceIcon = player =>
    style(list{
      border(
        px(1),
        #solid,
        player
        ->Belt.Option.map(_ => Style.Colors.lightGray)
        ->Belt.Option.getWithDefault(Style.Colors.error),
      ),
      height(px(20)),
      width(px(20)),
      position(absolute),
      right(zero),
      media("min-width: 640px", list{bottom(px(40))}),
    })
}

module Controls = {
  @react.component
  let make = (~state: Types.state) =>
    <div className=Styles.devicesContainer>
      <div className={Styles.deviceIcon(state.player)} />
    </div>
}

@react.component
let make = (~dispatch as _, ~state: Types.state) =>
  state.currentTrack
  ->Belt.Option.map(currentTrack => {
    let fraction = currentTrack.position /. float_of_int(currentTrack.track.durationMs)
    let percentage = fraction *. 100.0

    <div className=Styles.currentTrackContainer>
      <div
        className=Styles.albumCover
        style={ReactDOM.Style.make(
          ~backgroundImage="url('" ++ (currentTrack.track.imageUrl ++ "')"),
          (),
        )}
      />
      <div className=Styles.trackContainer>
        <div className=Styles.currentTrack> {React.string(currentTrack.track.name)} </div>
        <div className=Styles.currentArtist> {React.string(currentTrack.track.artist)} </div>
        <Controls state />
        <div className=Styles.progressBar>
          <div
            className=Styles.progression
            style={ReactDOM.Style.make(~width=Js.Float.toString(percentage) ++ "%", ())}
          />
        </div>
      </div>
    </div>
  })
  ->Belt.Option.getWithDefault(React.null)
