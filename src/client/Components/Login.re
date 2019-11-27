[@react.component]
let make = () => {
  <button onClick={_event => Spotify.authenticate()}>{React.string("login")}</button>;
};
