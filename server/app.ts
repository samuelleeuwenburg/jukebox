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
    getAllVotes,
} from './db';
const app: express.Application = express();

app.use(cors());
app.use(bodyParser.json());

app.get('/api/queue', (req, res) => {
    const db = getDb();

    getQueue(db, (err, tracks) => {
        db.close();
        res.send({ tracks });
    });
});

app.post('/api/queue', (req, res) => {
    const db = getDb();
    const track: Track = req.body;

    addTrackToQueue(db, track, (err) => {
        db.close();

        if (err) {
            console.log(`${new Date().toISOString()} - failed to add "${track.track_name}" to queue, `, err, '\n');

            res.status(500);
            return res.send({ error: err });
        }

        console.log(`${new Date().toISOString()} - added "${track.track_name}" to queue \n`);
        res.send({ status: 'ok' });
    });
});

app.post('/api/vote', (req, res) => {
    const db = getDb();
    const track: Track = req.body;

    voteOnTrack(db, track, err => {
        db.close();

        if (err) {
            console.log(`${new Date().toISOString()} - failed to vote for "${track.track_name}", `, err, '\n');

            res.status(500);
            return res.send({ error: err });
        }

        console.log(`${new Date().toISOString()} - voted for "${track.track_name}" \n`);
        res.send({ status: 'ok' });
    });
});

app.get('/api/votes', (req, res) => {
    const db = getDb();
    getAllVotes(db, (err, votes) => {
        db.close();

        if (err) {
            res.status(500);
            return res.send({ error: err });
        }
        res.send({ votes });
    });
});

let now: { cursor: number, track: null | Track } = {
    cursor: 0,
    track: null,
};

function play() {
    now.cursor = 0;
    now.track = null;

    const db = getDb();
    const currentTrack = getQueue(db, (err, tracks) => {
        if (!tracks || !tracks.length) {
            setTimeout(play, 5000);
            console.log(`${new Date().toISOString()} - no songs found, checking...`);
            db.close();
            return;
        }

        now.track = tracks[0];

        removeTrack(db, now.track.id, (err) => {
            if (!now.track) { return }
            console.log(`${new Date().toISOString()} - NOW PLAYING -> ${now.track.track_name}`);
            db.close();
            now.cursor = 0;

            const intervalId = setInterval(() => {
                if (!now.track) { return }
                if (now.cursor < now.track.duration_ms) {
                    now.cursor += 100;
                    return;
                }

                console.log(`${new Date().toISOString()} - ENDED -> ${now.track.track_name}`);
                clearInterval(intervalId);
                play();
            }, 100);
        });

    });
}
app.get('/api/now', (req, res) => {
    if (!now.track) {
        return res.send({ status: 'no track is playing' });
    }

    res.send(now);
});


app.listen(3000, () => {
    const db = getDb();
    createDb(db);
    db.close();

    play();

    console.log('Jukebox is playing on port 3000!');
});
