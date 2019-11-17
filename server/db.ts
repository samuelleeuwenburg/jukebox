import { Database } from 'sqlite3';
import { io } from './app';

function run(db: Database, sql: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
        db.run(sql, (err) => {
            err ? reject(err) : resolve();
        });
    });
}

function all<T>(db: Database, sql: string): Promise<T> {
    return new Promise<T>((resolve, reject) => {
        db.all(sql, (err, rows : T) => {
            err ? reject(err) : resolve(rows);
        });
    });
}

function get<T>(db: Database, sql: string): Promise<T> {
    return new Promise<T>((resolve, reject) => {
        db.get(sql, (err, rows : T) => {
            err ? reject(err) : resolve(rows);
        });
    });
}

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
export async function getQueue(db: Database) {
    const sql = `
        SELECT *, COUNT(votes.track_id) AS upvotes
        FROM queue, votes
        WHERE queue.id = votes.track_id
        GROUP BY queue.id
        ORDER BY upvotes DESC, last_updated ASC
    `;
    return all<Track[]>(db, sql);
}

export async function emitQueueUpdate(db: Database) {
    const tracks = await getQueue(db);

    return io.emit("queueUpdate", { tracks })
}

// @TODO: protect against sql injections 
export async function addTrackToQueue(db: Database, track: Track) {
    
    await run(db, `INSERT INTO queue (track_name, spotify_track_id, track_uri, duration_ms, user_id)
            VALUES("${track.track_name}", "${track.spotify_track_id}", "${track.track_uri}", "${track.duration_ms}", "${track.user_id}")`);

    return voteOnTrack(db, track);
}

export async function getTrackBySpotifyId(db: Database, spotifyTrackId: string) {
    return get<Track>(db, `SELECT * FROM queue WHERE spotify_track_id='${spotifyTrackId}' LIMIT 1`);
}

export async function voteOnTrack(db: Database, track: Track) {
    const trackFromDb = await getTrackBySpotifyId(db, track.spotify_track_id);
    return run(db, `INSERT INTO votes (user_id, track_id) VALUES("${trackFromDb.user_id}", "${trackFromDb.id}")`);
}

export async function removeTrack(db: Database, trackId: number) {
    
    await run(db, `DELETE FROM queue WHERE id='${trackId}'`);
    await run(db, `DELETE FROM votes WHERE track_id='${trackId}'`);
}

export async function getAllVotes(db: Database) {
    return all<Vote>(db, `SELECT * FROM votes ORDER BY track_id`);
}