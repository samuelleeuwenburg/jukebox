import express = require('express');
import bodyParser = require('body-parser');
import cors = require('cors');
import {
    createDb,
    getDb,
    getQueue,
    addTrackToQueue,
    Track,
    voteOnTrack,
    removeTrack,
    getAllUserVotes,
    emitQueueUpdate
} from './db';
const app = express();
const server = require('http').createServer(app);
export const io = require('socket.io')(server);

app.use(cors());
app.use(bodyParser.json());

app.get('/api/queue', async (req, res) => {
    const db = getDb();

    try {
        const tracks = await getQueue(db);
        db.close();
        res.send({ tracks });
    } catch (err) {
        res.status(500);
        res.send({ error: err });
    }
});

app.post('/api/queue', async (req, res) => {
    const track: Track = req.body;

    try {
        const db = getDb();
        await addTrackToQueue(db, track);

        await emitQueueUpdate(db);

        db.close();
        console.log(`${new Date().toISOString()} - added "${track.track_name}" to queue \n`);


        res.send({ status: 'ok' });

    } catch(err) {
        console.log(`${new Date().toISOString()} - failed to add "${track.track_name}" to queue, `, err, '\n');
        res.status(500);
        return res.send({ error: err });
    }
});

app.post('/api/vote', async (req, res) => {
    const track: Track = req.body;

    try {
        const db = getDb();
        await voteOnTrack(db, track);
        await emitQueueUpdate(db);
        
        db.close();
        console.log(`${new Date().toISOString()} - voted for "${track.track_name}" \n`);
        res.send({ status: 'ok' });
    } catch(err) {
        console.log(`${new Date().toISOString()} - failed to vote for "${track.track_name}", `, err, '\n');
        res.status(500);
        return res.send({ error: err });
    }
});

app.get('/api/votes/:userId', async (req, res) => {
    const db = getDb();

    try {
        const userId = req.params.userId;

        const votes = await getAllUserVotes(db, userId);
        res.send({ votes });

    } catch (err) {
        res.status(500);
        return res.send({ error: err });
    }
});

let now: { cursor: number, track: null | Track } = {
    cursor: 0,
    track: null,
};

async function play() {
    now.cursor = 0;
    now.track = null;

    const db = getDb();
    const tracks = await getQueue(db);

    if (!tracks || !tracks.length) {
        setTimeout(play, 5000);
        console.log(`${new Date().toISOString()} - no songs found, checking...`);
        db.close();
        return;
    }

    now.track = tracks[0];
    await removeTrack(db, now.track.id);
    await emitQueueUpdate(db);
    io.emit('currentTrackUpdate', now.track)

    console.log(`${new Date().toISOString()} - NOW PLAYING -> ${now.track.track_name}`);
    db.close();
    now.cursor = 0;

    const intervalId = setInterval(() => {
        if (!now.track) { return }
        if (now.cursor < now.track.duration_ms) {
            now.cursor += 100;
            io.emit('trackProgressUpdate', now)
            return;
        }

        console.log(`${new Date().toISOString()} - ENDED -> ${now.track.track_name}`);
        clearInterval(intervalId);
        play();
    }, 100);
}

app.get('/api/now', (req, res) => {
    if (!now.track) {
        return res.send({ status: 'no track is playing' });
    }

    res.send(now.track);
});

server.listen(3000, () => {
    const db = getDb();
    createDb(db);
    db.close();

    play();

    console.log('Jukebox is playing on port 3000!');
});
