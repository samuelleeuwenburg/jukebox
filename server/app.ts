import express = require('express')
import cors = require('cors')
import path = require('path')
import { Socket, Server } from 'socket.io'

const app = express()
const server = require('http').createServer(app)
const io: Server = require('socket.io')(server, { path: '/socket.io' })

app.use(cors())

interface Track {
    id: string;
    name: string;
    uri: string;
    userId: string;
    imageUrl: string;
    durationMs: number;
    upvotes: string[];
    timestamp: number;
}

interface Vote {
    userId: string;
    timestamp: number;
}

interface CurrentTrack {
    track: Track;
    position: number;
    timestamp: number;
}

interface Queue {
    tracks: Track[];
    currentTrack: CurrentTrack | null;
}

app.get('/debug', (req, res) => {
    res.sendFile(path.join(__dirname + '/debug.html'))
})

server.listen(3000, () => {
    console.log('Jukebox is playing on port 3000!')
    const state = getInitialState();

    loop(state, io)

    io.on('connect', (socket: Socket) => {
        socket.on('vote', (data: { trackId: string, userId: string }) => {
            log('received vote for ->', data.trackId)
            voteOnTrack(state, data.trackId, data.userId)
            io.emit('newQueue', state)
        })

        socket.on('addTrack', (partialTrack: Track) => {
            log('received track', partialTrack)
            const track: Track = {
                ...partialTrack,
                timestamp: Date.now(),
                upvotes: [partialTrack.userId]
            }

            addTrack(state, track)
            io.emit('newQueue', state)
        })

        socket.on('getQueue', () => {
            socket.emit('newQueue', state)
        })
    })
})

function loop(state: Queue, io: Server) {
    state.currentTrack = getNewCurrentTrack(state)

    if (!state.currentTrack) {
        setTimeout(() => loop(state, io), 2000)
        log('no tracks in queue, waiting...')
        return
    }

    removeTrack(state, state.currentTrack.track.id)
    log('NOW PLAYING ->', state.currentTrack.track)
    io.emit('newQueue', state)

    const intervalId = setInterval(() => {
        if (!state.currentTrack) {
            clearInterval(intervalId)
            loop(state, io)
            return
        }

        const now = Date.now()
        const songEndsAt = state.currentTrack.timestamp
            + state.currentTrack.track.durationMs
        state.currentTrack.position = now - state.currentTrack.timestamp

        if (now > songEndsAt) {
            log('ENDED ->', state.currentTrack.track)
            clearInterval(intervalId)
            loop(state, io)
        }
    }, 100)
}

function getInitialState(): Queue {
    return { tracks: [], currentTrack: null }
}

function getNewCurrentTrack(state: Queue): CurrentTrack | null {
    if (!state.tracks.length) {
        return null
    }

    sortQueue(state)
    const track = state.tracks[0]

    return {
        track,
        timestamp: Date.now(),
        position: 0,
    }
}

function voteOnTrack(state: Queue, trackId: string, userId: string) {
    state.tracks = state.tracks.map(track => {
        return track.id === trackId && !track.upvotes.includes(userId)
            ? {...track, upvotes: [...track.upvotes, userId] }
            : track
    })
    sortQueue(state)
}

function addTrack(state: Queue, track: Track) {
    state.tracks = [...state.tracks, track]
    sortQueue(state)
}

function removeTrack(state: Queue, trackId: string) {
    log('removing track ->', trackId)
    state.tracks = state.tracks.filter(track => track.id !== trackId)
}

function sortQueue(state: Queue) {
    state.tracks = state.tracks
        .sort((a, b) => a.upvotes.length > b.upvotes.length ? -1 : 1)
}

function log(...messages: any[]) {
    console.log(new Date().toISOString(), ...messages)
}

