import { Database } from 'sqlite3';

type RowCallback<T> = (err: Error | null, rows: T) => void;
type ErrorCallback = (err: Error | null) => void;

export interface Track {
    id?: number;
    track_name: string;
    track_id: string;
    duration_ms: string;
    user_id: string;
}

export function getDb(): Database {
    const db = new Database('./jukebox.db', err => {
        if (err) {
            console.error(err.message);
        }
    });

    // Poor man's migrations
    db.run("CREATE TABLE IF NOT EXISTS queue (id INTEGER PRIMARY KEY, track_name TEXT, track_id TEXT, duration_ms INTEGER, user_id TEXT, last_updated DATETIME DEFAULT CURRENT_TIMESTAMP)");
    db.run("CREATE TABLE IF NOT EXISTS votes (id INTEGER PRIMARY KEY, user_id TEXT, track_id INTEGER)");

    return db;
}

// @TODO: protect against sql injections 
export function getQueue(db: Database, callback: RowCallback<Track[]>): void {
    const sql = "SELECT * FROM queue";
    db.all(sql, callback);
}

// @TODO: protect against sql injections 
export function addTrackToQueue(db: Database, track: Track, callback: ErrorCallback): void {
    db.run(`INSERT INTO queue
       (track_name, track_id, duration_ms, user_id)
       VALUES("${track.track_name}", "${track.track_id}", "${track.duration_ms}", "${track.user_id}")
   `, callback);
}
