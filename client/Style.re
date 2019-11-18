module Colors = {
    open Css;

    let error = hex("ff0000");
    let darkGray = hex("141518")

    Css.(
        global("body", [backgroundColor(darkGray), margin(zero)])
    );
    
    Css.(
        global("*, *:after, *:before", [boxSizing(borderBox)])
    );

};
