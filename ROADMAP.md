# Instant Playlist — Roadmap Ideas

Ideas for future versions. None of these are committed. They're here to pick from.

## The problem: most people don't have their own music

v1 plays only local files (see `SPEC.md` → Source of Songs). That suits people who
already keep a music folder, but a new user with no files opens an empty library.
The ideas below are ways to get audio into the app without changing what it is:
**tag your songs, then build playlists from tag filters.**

### 1. Self-hosted music servers (Subsonic / Navidrome / Jellyfin)

The best fit, and the biggest feature on this list. People who sync music with
Syncthing often run one of these servers too, and iOS has few good clients for
them. Tag-filter playlists over a whole server library would set the app apart.

- Connect to a server, browse it, and stream or cache songs
- Store tags in the app, keyed by the server's song ID

### 2. Importing from cloud storage

Make it easy to bring in files from iCloud Drive, Google Drive or Dropbox through
the iOS Files app. Many people have old MP3s sitting in cloud storage.

### 3. Free, legal music catalogs

Jamendo, Free Music Archive and Internet Archive offer APIs for Creative Commons
music. A new user would have something to play and tag on day one, which also
fixes the empty-library problem during onboarding. This is the quickest win.

### 4. Audiobooks and lectures

These are local files too, so the app already plays them. To make it good for them:

- Remember the playback position for long files
- Mention this use in the App Store description

## Considered: podcasts / RSS feeds

**Verdict: not as a full podcast app.** Apple Podcasts, Overcast and Pocket Casts
are free and mature. Podcast users expect a lot:

- played state and resume position
- variable speed
- chapters
- background refresh and auto-download
- OPML import
- show discovery

Building all of that is months of work that doesn't use the tag features.

**Possible later, kept small:** treat an RSS feed as another source of audio files.
Downloaded episodes go into the library and get tagged like songs, so a user could
build a playlist like "history + under 30 min + unplayed" across several shows.
Scope: add a feed URL, download episodes, remember playback position. Build it
only if current users ask for it.

## Ruled out

- **Getting audio from YouTube or Spotify:** Apple would reject the app, and it's a
  legal risk.
