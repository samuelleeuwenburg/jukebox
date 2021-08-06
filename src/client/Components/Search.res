open Webapi.Dom

module Styles = {
  open Css

  let searchContainer = style(list{maxWidth(px(500)), flexBasis(pct(100.0))})

  let inputContainer = style(list{position(relative)})

  let input = style(list{paddingLeft(px(25)), paddingRight(px(25))})

  let trackName = style(list{
    fontSize(px(18)),
    fontWeight(bold),
    textOverflow(ellipsis),
    overflow(hidden),
    whiteSpace(nowrap),
  })

  let artistName = style(list{
    fontSize(px(16)),
    color(Style.Colors.lightGray),
    textOverflow(ellipsis),
    overflow(hidden),
    whiteSpace(nowrap),
  })

  let trackInfoContainer = style(list{
    display(#flex),
    flexDirection(column),
    justifyContent(center),
    width(#calc(#sub, pct(100.0), px(80))),
  })

  let trackContainer = style(list{
    display(#flex),
    flexWrap(wrap),
    flexDirection(row),
    marginBottom(px(20)),
    cursor(#pointer),
    selector("&:hover", list{backgroundColor(Style.Colors.darkGray)}),
  })

  let albumCover = style(list{
    width(px(60)),
    height(px(60)),
    backgroundPosition(center),
    backgroundSize(cover),
    marginRight(px(20)),
  })

  let searchButtonContainer = showSearch =>
    style(list{
      position(absolute),
      left(zero),
      bottom(zero),
      cursor(#pointer),
      selector(
        "& svg path",
        list{SVG.fill(showSearch ? Style.Colors.lightestGray : Style.Colors.lightGray)},
      ),
    })

  let resultsContainer = style(list{
    position(absolute),
    zIndex(999),
    backgroundColor(Style.Colors.darkerGray),
    top(px(60)),
    padding(px(20)),
    transform(translateX(px(-20))),
    width(pct(100.0)),
    overflow(auto),
    left(px(20)),
    maxHeight(#calc(#sub, vh(100.0), px(60))),
    height(vh(100.0)),
    media(
      "(min-width: 640px)",
      list{
        padding2(~v=px(20), ~h=px(40)),
        width(px(580)),
        transform(translateX(px(-40))),
        left(initial),
        height(initial),
      },
    ),
  })

  let clearIconContainer = (showSearch, hasQuery) =>
    style(list{
      position(absolute),
      right(zero),
      bottom(zero),
      showSearch || hasQuery ? display(inline) : display(none),
      cursor(#pointer),
    })

  let recentSearchQuery = style(list{
    fontSize(px(20)),
    fontWeight(bold),
    paddingTop(px(5)),
    paddingBottom(px(5)),
    cursor(#pointer),
    selector("&:hover", list{backgroundColor(Style.Colors.darkGray)}),
  })

  let recentSearchesTitle = style(list{
    fontSize(px(20)),
    fontWeight(bold),
    color(Style.Colors.lightGray),
    marginBottom(px(5)),
  })
}

module Track = {
  @react.component
  let make = (~dispatch, ~track: Spotify.track, ~user: Spotify.user, ~socket: SocketIO.socket) => {
    let artist = List.hd(track.artists)
    let image =
      track.album.images
      |> List.sort((a: Spotify.image, b: Spotify.image) => b.width - a.width)
      |> List.hd

    let addTrack = React.useCallback0(() => {
      let data = {
        open Json.Encode
        object_(list{
          ("id", string(track.id)),
          ("name", string(track.name)),
          ("artist", string(artist.name)),
          ("uri", string(track.uri)),
          ("userId", string(user.id)),
          ("imageUrl", string(image.url)),
          ("durationMs", int(track.durationMs)),
        })
      }

      Js.log("adding track")
      Js.log(data)

      dispatch(Types.ClearSearch)
      socket->SocketIO.emit("addTrack", data) |> ignore
    })

    <li className=Styles.trackContainer onClick={_ => addTrack()}>
      <div
        className=Styles.albumCover
        style={ReactDOM.Style.make(~backgroundImage="url('" ++ (image.url ++ "')"), ())}
      />
      <div className=Styles.trackInfoContainer>
        <div className=Styles.trackName> {React.string(track.name)} </div>
        <div className=Styles.artistName> {React.string(artist.name)} </div>
      </div>
    </li>
  }
}

@react.component
let make = (~socket: SocketIO.socket, ~dispatch, ~state: Types.state) => {
  let (showSearch, setShowSearch) = React.useState(() => false)
  let searchContainerRef = React.useRef(Js.Nullable.null)

  let getTracks = query => {
    Js.log2(query, "get tracks query")

    LocalStorage.setQueryToStorage(query)

    switch state.token {
    | None => Js.log("search: trying to call `getTracks` without token")
    | Some(token) => {
        open Js.Promise
        Spotify.getTracks(token, query) |> then_(tracks => {
          dispatch(Types.UpdateResults(tracks))
          resolve(tracks)
        })
      } |> ignore
    }
  }

  let debouncedGetTracks = Debouncer.make(~wait=500, query => getTracks(query))

  let onChanges = (value: string) =>
    if value === "" {
      dispatch(Types.ClearSearch) |> ignore
    } else {
      dispatch(Types.UpdateQuery(value)) |> ignore
      debouncedGetTracks(value)
    }

  let onFocus = () => setShowSearch(_ => true)

  let closeRecentSearches = () => setShowSearch(_ => false)

  let closeSearch = () => {
    dispatch(Types.ClearSearch)
    closeRecentSearches()
  }

  let handleClickoutside = (domElement: Dom.element, target: Dom.mouseEvent, fn) => {
    let targetElement = MouseEvent.target(target) |> EventTarget.unsafeAsElement
    let elementContainsTarget = domElement |> Element.contains(targetElement)
    elementContainsTarget ? () : fn()
  }

  let handleMouseDown = event =>
    searchContainerRef.current
    ->Js.Nullable.toOption
    ->Belt.Option.map(refValue => handleClickoutside(refValue, event, closeRecentSearches))
    ->ignore

  React.useEffect1(() => {
    if showSearch {
      Document.addClickEventListener(handleMouseDown, document)
    } else {
      Document.removeClickEventListener(handleMouseDown, document)
    }
    Some(() => Document.removeClickEventListener(handleMouseDown, document))
  }, [showSearch])

  let recentSearches = {
    let onQueryClick = (query: string) => {
      dispatch(Types.UpdateQuery(query))
      getTracks(query)
    }

    let queries =
      LocalStorage.getRecentSearchesFromStorage()
      |> List.map(query =>
        <div className=Styles.recentSearchQuery key=query onClick={_ => onQueryClick(query)}>
          {React.string(query)}
        </div>
      )
      |> Array.of_list
      |> React.array

    <div className=Styles.resultsContainer>
      <div className=Styles.recentSearchesTitle> {React.string("Recent searches")} </div> queries
    </div>
  }

  let results =
    state.results
    ->Belt.Option.flatMap(results => state.user->Belt.Option.map(user => (results, user)))
    ->Belt.Option.map(values => {
      open Spotify
      let (results, user) = values

      let results =
        results.items
        |> List.map(track => <Track key=track.uri socket track user dispatch />)
        |> Array.of_list
        |> React.array

      <ul className=Styles.resultsContainer> results </ul>
    })
    ->Belt.Option.getWithDefault(React.null)

  <div className=Styles.searchContainer ref={ReactDOM.Ref.domRef(searchContainerRef)}>
    <div className=Styles.inputContainer>
      <span className={Styles.searchButtonContainer(showSearch)}>
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
      <input
        onFocus={_ => onFocus()}
        className=Styles.input
        placeholder="Search for tracks"
        value=state.query
        onChange={event => onChanges(ReactEvent.Form.target(event)["value"])}
      />
      <span
        className={Styles.clearIconContainer(showSearch, String.length(state.query) > 1)}
        onClick={_ => closeSearch()}>
        <svg width="13.414" height="13.414" viewBox="0 0 13.414 13.414">
          <g id="Group_2" transform="translate(-1180.703 -25.116)">
            <line
              id="Line_31"
              x2="12"
              y2="12"
              transform="translate(1181.41 25.823)"
              fill="none"
              stroke="#b3b3b3"
              strokeWidth="1"
            />
            <line
              id="Line_32"
              y1="12"
              x2="12"
              transform="translate(1181.41 25.823)"
              fill="none"
              stroke="#b3b3b3"
              strokeWidth="1"
            />
          </g>
        </svg>
      </span>
    </div>
    {showSearch ? recentSearches : React.null}
    {showSearch ? results : React.null}
  </div>
}
