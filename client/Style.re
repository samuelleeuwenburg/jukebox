module Colors = {
    open Css;

    let error = hex("ff0000");

    let lightestGray = hex("B3B3B3");
    let lightGray = hex("858585")
    let gray = hex("565656");
    let darkGray = hex("505050")
    let darkerGray = hex("252526");
    let darkestGray = hex("141518");

    global("body", [
      backgroundColor(darkestGray),
      margin(zero),
      color(lightestGray),
      fontFamily("sans-serif"),
    ]);

    global("h1, h2, h3", [
      margin3(zero, zero, px(20)),
    ]);

    global("button", [
      color(hex("fff")),
      backgroundColor(darkGray)
    ]);
    
    global("ul, ol", [
      margin(zero),
      padding(zero)
    ]);

    global("li", [
      listStyleType(none)
    ]);

    global("*, *:after, *:before", [
      boxSizing(borderBox)
    ]);

    global("input", [
      margin(zero),
      padding(zero),
      border(px(0), `solid, transparent),
      borderBottom(px(1), `solid, lightGray),
      display(inlineBlock),
      verticalAlign(middle),
      whiteSpace(normal),
      background(none),
      lineHeight(px(13)),
      fontWeight(bold),
      width(pct(100.0)),
      outline(px(0), none, `hex("000000")),
      /* Browsers have different default form fonts */
      color(lightestGray),
      fontSize(px(20)),
      selector("&:focus", [
         borderBottom(px(1), `solid, lightestGray),
      ])
    ])
    
    
};
