open CssJs

module Colors = {
  let error = hex("AF2415")
  let lightestGray = hex("B3B3B3")
  let lightGray = hex("858585")
  let gray = hex("565656")
  let darkGray = hex("505050")
  let darkerGray = hex("252526")
  let darkestGray = hex("141518")
}

global(.
  "body",
  [
    backgroundColor(Colors.darkestGray),
    margin(zero),
    color(Colors.lightestGray),
    fontFamily(#sansSerif),
  ],
)

global(. "h1, h2, h3, p, ol, ul, li, pre, input, textarea", [lineHeight(px(22))])

global(. "h1, h2, h3", [margin3(~top=zero, ~h=zero, ~bottom=px(20))])

global(. "button", [cursor(pointer), color(hex("fff")), backgroundColor(Colors.darkGray)])

global(. "ul, ol", [margin(zero), padding(px(20))])

global(. "li", [])

global(. "*, *:after, *:before", [boxSizing(borderBox)])

global(.
  "input",
  [
    margin(zero),
    padding(zero),
    border(px(0), #solid, transparent),
    borderBottom(px(1), #solid, Colors.lightGray),
    display(inlineBlock),
    verticalAlign(middle),
    whiteSpace(normal),
    background(none),
    lineHeight(px(13)),
    fontWeight(bold),
    width(pct(100.0)),
    outline(px(0), none, #hex("000000")),
    /* Browsers have different default form fonts */
    color(Colors.lightestGray),
    fontSize(px(20)),
    selector("&:focus", [borderBottom(px(1), #solid, Colors.lightestGray)]),
  ],
)
