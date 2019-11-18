import { io } from './app';
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

interface Now {
    cursor: number;
    track: null | Track;
    timestamp: number
}

export const now: Now = {
    cursor: 0,
    track: null,
    timestamp: 0,
};

export async function play() {
    const db = getDb();
    const tracks = await getQueue(db);

    if (!tracks || !tracks.length) {
        setTimeout(play, 5000);
        console.log(`${new Date().toISOString()} - no songs found, checking...`);
        db.close();
        return;
    }

    now.track = tracks[0];
    now.cursor = 0;
    now.timestamp = Date.now();

    await removeTrack(db, now.track.id);
    await emitQueueUpdate(db);
    db.close();

    io.emit('currentTrackUpdate', now);
    console.log(`${new Date().toISOString()} - NOW PLAYING -> ${now.track.track_name}`);

    const intervalId = setInterval(() => {
        if (!now.track) { return }
        if (now.cursor < now.track.duration_ms) {
            now.cursor = Date.now() - now.timestamp;
            return;
        }

        console.log(`${new Date().toISOString()} - ENDED -> ${now.track.track_name}`);
        clearInterval(intervalId);
        play();
    }, 160);
}

