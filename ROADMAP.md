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

### 5. Apple Music via MusicKit (best streaming option)

Apple's MusicKit plays Apple Music songs inside the app, using the user's own
subscription. The app controls the queue, so tag-filter playlists work the same
way they do with local files. It also supports background and lock-screen playback.

- Tags stay local, keyed by the Apple Music song ID
- No user limits or approval process: included with the Apple Developer membership
- Downsides:
  - users need an Apple Music subscription
  - iOS-first (MusicKit for Android is more limited)
  - Flutter needs a plugin or some native Swift code

**Design tip for any streaming source:** save each song's **ISRC** (a standard
recording ID carried by Spotify, Apple Music and most music files) next to its
tags. Tags can then follow the same song across local files and services, so users
keep them if they switch.

## Later: Spotify (once the app has a large user base)

**How it would work:**

- The Spotify iOS SDK tells the installed Spotify app which song to play.
- Audio plays inside Spotify under the user's own account. The app acts as a
  remote control and keeps its tags locally, keyed by Spotify song ID.
- The Web API handles search, the user's saved songs, and playlists.
- A tag-filter playlist either queues the matching songs one by one or becomes a
  Spotify playlist that the app then plays.
- Flutter plugin: `spotify_sdk`.

**Why not now:**

- **Access cap.** A new Spotify app is limited to about 25 hand-added users. Since
  2025, Spotify only grants wider access to registered organisations with large
  user bases (around 250k monthly users). Re-check the current rules before
  starting.
- **Premium only.** On-demand playback needs Spotify Premium.
- **Metadata limits.** Spotify's terms limit how much catalog metadata can be
  stored. Song IDs next to the app's own tags are fine.

**Revisit when the app is near 250k monthly users** and has a registered business
behind it.

### Growth idea: let users unlock Spotify support together

Turn the Spotify goal into a reason to share the app. An in-app "Coming features"
screen would:

- explain that streaming-service support needs a bigger user base
- show progress toward that goal
- offer a "Share Instant Playlist" button (iOS share sheet with the App Store link)

Things to watch:

- **Approval isn't guaranteed.** Spotify can still say no, even at 250k users. Word
  it as "we'll apply," not "it unlocks at 250k."
- **Trademark.** Avoid putting Spotify's name or logo in marketing for a feature
  that doesn't exist yet. Use something like "more streaming services" in App
  Store text.
- **App Store rules.** Asking users to share is fine. Don't reward shares or
  reviews with features or perks.
- **Overpromising.** 250k is a long way off for an indie app. A goal people can
  see moving (feature votes, smaller milestones like Apple Music) keeps sharing
  going better than one distant number.

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

- **Extracting or downloading audio from YouTube or Spotify:** Apple would reject
  the app, and it's a legal risk.
- **YouTube as a playback source:** YouTube's API terms forbid audio-only or
  background playback, separating audio from video, caching, and hiding the
  player. YouTube Music has no public API. The only allowed version is opening
  one video at a time in a visible player. That means no auto-advance and no real
  playlists, so it doesn't fit this app.
