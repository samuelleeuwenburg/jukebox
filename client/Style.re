module Colors = {
    open Css;

    let error = hex("ff0000");

    let lightestGray = hex("B3B3B3");
    let lightGray = hex("858585")
    let gray = hex("565656");
    let darkGray = hex("252526");
    let darkestGray = hex("141518");

    global("body", [
      backgroundColor(darkestGray),
      margin(zero),
      color(hex("dbdbdb")),
      fontFamily("sans-serif"),
    ]);

    global("ul, ol", [
       margin(zero),
       padding(zero)
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
      /* Browsers have different default form fonts */
      color(lightestGray),
      fontSize(px(20)),
      selector("&:focus", [
         borderBottom(px(1), `solid, lightestGray),
      ])
    ])
    
    
};
