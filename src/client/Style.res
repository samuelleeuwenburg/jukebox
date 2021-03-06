module Colors = {
  open Css

  let error = hex("AF2415")

  let lightestGray = hex("B3B3B3")
  let lightGray = hex("858585")
  let gray = hex("565656")
  let darkGray = hex("505050")
  let darkerGray = hex("252526")
  let darkestGray = hex("141518")

  global(
    "body",
    list{
      backgroundColor(darkestGray),
      margin(zero),
      color(lightestGray),
      fontFamily(#sansSerif)
    },
  )

  global("h1, h2, h3", list{margin3(~top=zero, ~h=zero, ~bottom=px(20))})

  global("button", list{color(hex("fff")), backgroundColor(darkGray)})

  global("ul, ol", list{margin(zero), padding(px(20))})

  global("li", list{listStyleType(none)})

  global("*, *:after, *:before", list{boxSizing(borderBox)})

  global(
    "input",
    list{
      margin(zero),
      padding(zero),
      border(px(0), #solid, transparent),
      borderBottom(px(1), #solid, lightGray),
      display(inlineBlock),
      verticalAlign(middle),
      whiteSpace(normal),
      background(none),
      lineHeight(px(13)),
      fontWeight(bold),
      width(pct(100.0)),
      outline(px(0), none, #hex("000000")),
      /* Browsers have different default form fonts */
      color(lightestGray),
      fontSize(px(20)),
      selector("&:focus", list{borderBottom(px(1), #solid, lightestGray)}),
    },
  )
}
