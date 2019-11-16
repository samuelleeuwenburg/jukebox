import { Database } from 'sqlite3';

type RowCallback<T> = (err: Error | null, rows: T) => void;
type ErrorCallback = (err: Error | null) => void;

export interface Track {
    id: number;
    track_name: string;
    spotify_track_id: string;
    track_uri: string;
    duration_ms: number;
    user_id: string;
}

export interface Vote {
    id: number;
    user_id: string;
    track_id: number;
}

export function createDb(db: Database) {
    // Poor man's migrations
    db.run(`CREATE TABLE IF NOT EXISTS queue (
        id INTEGER PRIMARY KEY,
        track_name TEXT,
        spotify_track_id TEXT,
        track_uri TEXT,
        duration_ms INTEGER,
        user_id TEXT,
        last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
        unique (spotify_track_id)
    )`, err => err ? console.log('failed to create "queue" table', err) : null);

    db.run(`CREATE TABLE IF NOT EXISTS votes (
        id INTEGER PRIMARY KEY,
        user_id TEXT, 
        track_id INTEGER,
        unique (track_id, user_id)
    )`, err => err ? console.log('failed to create "votes" table', err) : null);
}

export function getDb(): Database {
    return new Database('./jukebox.db', err => {
        if (err) {
            console.error(err.message);
        }
    });
}

// @TODO: protect against sql injections 
export function getQueue(db: Database, callback: RowCallback<Track[]>) {
    const sql = `
        SELECT *, COUNT(votes.track_id) AS upvotes
        FROM queue, votes
        WHERE queue.id = votes.track_id
        GROUP BY queue.id
        ORDER BY upvotes DESC, last_updated ASC
    `;
    db.all(sql, callback);
}

// @TODO: protect against sql injections 
export function addTrackToQueue(db: Database, track: Track, callback: ErrorCallback) {
    db.run(`INSERT INTO queue (track_name, spotify_track_id, track_uri, duration_ms, user_id)
            VALUES("${track.track_name}", "${track.spotify_track_id}", "${track.track_uri}", "${track.duration_ms}", "${track.user_id}")
   `, (err) => {
       if (err) {
           return callback(err);
       }

       voteOnTrack(db, track, callback);
   });
}

export function getTrackBySpotifyId(db: Database, spotifyTrackId: string, callback: RowCallback<Track>) {
    db.get(`SELECT * FROM queue WHERE spotify_track_id='${spotifyTrackId}' LIMIT 1`, callback);
}

export function voteOnTrack(db: Database, track: Track, callback: ErrorCallback) {
    getTrackBySpotifyId(db, track.spotify_track_id, (err, track) => {
        if (err) {
            return callback(err);
        }

        db.run(`INSERT INTO votes (user_id, track_id)
                VALUES("${track.user_id}", "${track.id}")
        `, callback);
    })
}

export function removeTrack(db: Database, trackId: number, callback: ErrorCallback) {
    db.run(`DELETE FROM queue WHERE id='${trackId}'`, err => {
        if (err) {
            return callback(err);
        }
        db.run(`DELETE FROM votes WHERE track_id='${trackId}'`, callback);
    });
}

export function getAllVotes(db: Database, callback: RowCallback<Vote>) {
    db.all(`SELECT * FROM votes ORDER BY track_id`, callback);
}

