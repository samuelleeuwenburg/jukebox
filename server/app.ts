import express = require('express');
import bodyParser = require('body-parser');
import cors = require('cors');
import { getDb, getQueue, addTrackToQueue, Track } from './db';
const app: express.Application = express();


app.use(cors());
app.use(bodyParser.json());

app.get('/api/queue', function (req, res) {
    const db = getDb();
    getQueue(db, (err, tracks) => {
        db.close();
        res.send({ tracks })
    });
});

app.post('/api/queue', (req, res) => {
    const db = getDb();
    const track: Track = req.body

    addTrackToQueue(db, track, (err) => {
        db.close();

        if (err) {
            console.log(`${new Date().toISOString()} - failed to add "${track.track_name}" to queue, `, err, '\n');

            res.status(500);
            res.send({ error: err })
        }

        console.log(`${new Date().toISOString()} - added "${track.track_name}" to queue \n`);
        res.send({ status: 'ok' })
    });
});

app.listen(3000, function () {
    console.log('Jukebox is playing on port 3000!');
});
