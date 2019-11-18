module Colors = {
    open Css;

    let error = hex("ff0000");
    let darkGray = hex("141518");

    global("body", [
           backgroundColor(darkGray),
           margin(zero),
           color(hex("dbdbdb")),
           fontFamily("sans-serif"),
    ]);

    global("*, *:after, *:before", [
           boxSizing(borderBox)
    ]);
};
