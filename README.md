# Jukebox
The idea is to revive an old jukebox app that used to be available on the Spotify apps platform (before it was killed).

## TODO
- play songs from state (maybe on external device?)
- submit song to backend
- keep track of songs
- vote on songs (one vote per user)
- refresh token before it expires

## Run client

```sh
npm install
npm run client:server
# in a new tab
npm run client:start
```

## Run server

```sh
npm run server:dev
```

## Build client & server
```sh
npm run client:build
npm run server:build
```
