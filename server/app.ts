import express = require('express');
import sqlite3 = require('sqlite3');
const app: express.Application = express();

const db = new sqlite3.Database('./jukebox.db', sqlite3.OPEN_READWRITE, err => {
    err ? console.error(err.message)
        : console.log('Connected to jukebox.db database');
});

app.get('/', function (req, res) {
    res.send('Hello World!!');
});

app.listen(3000, function () {
    console.log('Jukebox is playing on port 3000!');
});
