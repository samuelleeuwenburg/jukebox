# Jukebox
The idea is to revive an old jukebox app that used to be available on the Spotify apps platform (before it was killed).

## Run

```sh
npm install
npm run server
# in a new tab
npm start
```

# Bundle for Production

We've included a convenience `UNUSED_webpack.config.js`, in case you want to ship your project to production. You can rename and/or remove that in favor of other bundlers, e.g. Rollup.

We've also provided a barebone `indexProduction.html`, to serve your bundle.

```sh
npm install webpack webpack-cli
# rename file
mv UNUSED_webpack.config.js webpack.config.js
# call webpack to bundle for production
./node_modules/.bin/webpack
open indexProduction.html
```
