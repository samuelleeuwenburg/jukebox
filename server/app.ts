import express = require('express');
import sqlite3 = require('sqlite3');
import bodyParser = require('body-parser');
import cors = require('cors');
const app: express.Application = express();

const db = new sqlite3.Database('./jukebox.db', err => {
    err ? console.error(err.message)
        : console.log('Connected to jukebox.db database');
});

db.run("CREATE TABLE IF NOT EXISTS queue (id INTEGER PRIMARY KEY, track_name TEXT, track_id TEXT, duration_ms INTEGER, user_id TEXT, last_updated TIMESTAMP)");
db.run("CREATE TABLE IF NOT EXISTS votes (id INTEGER PRIMARY KEY, user_id TEXT, track_id INTEGER)");

app.use(cors());
app.use(bodyParser.json());

app.get('/queue', function (req, res) {
    const sql = "SELECT * FROM queue";

    db.all(sql, (err, rows) => {
        res.send({ 
            tracks: rows
        })
    });
});

app.post('/queue', (req, res) => {
    const body = req.body
    db.run(`INSERT INTO queue (track_name, track_id, duration_ms, user_id, last_updated) VALUES("${body.track_name}", "${body.track_id}", "${body.duration_ms}", "${body.user_id}", "${body.last_updated}")`)

    res.send('item set')
});

app.listen(3000, function () {
    console.log('Jukebox is playing on port 3000!');
});
