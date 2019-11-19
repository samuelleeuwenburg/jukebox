module Colors = {
    open Css;

    let error = hex("ff0000");
    let gray = hex("565656");
    let darkGray = hex("141518");

    global("body", [
       backgroundColor(darkGray),
       margin(zero),
       color(hex("dbdbdb")),
       fontFamily("sans-serif"),
       margin2(zero, px(40))
    ]);

    global("ul, ol", [
       margin(zero),
       padding(zero)
    ]);

    global("*, *:after, *:before", [
       boxSizing(borderBox)
    ]);
};
