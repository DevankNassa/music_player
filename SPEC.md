# Insta-Playlist — Spec Sheet

## Overview

A music player that builds playlists on the fly based on rules you set — tags on songs (mood, occasion, language, explicit content, artist, genre, and anything else you want to track), not a fixed set of built-in categories.

## Feature: Quick Tag Mode

A fast tagging workflow: the song plays while its current tags are shown on screen, and you can add/remove tags without stopping playback — so you can tag your library by just listening through it.

### Mechanic

- Plays songs (e.g. the whole library, or an untagged-first queue) one after another, auto-advancing when a song ends.
- Shows the current song's existing tags live on screen while it plays.
- Tapping/pressing a tag toggles it on or off for the song currently playing — no pausing required.
- Adding a brand-new tag (one that doesn't exist yet) should be just as fast as toggling an existing one.
- Frequently-used tags should be easy to reach (e.g. always-visible shortcuts) rather than buried in a search/list.

### Open questions (not yet decided)

- Keyboard shortcuts / hotkeys for toggling tags vs. touch-only?
- Skip/back controls — can you jump to the next song before it ends, or go back to re-tag the previous one?
- Should it prioritize untagged or rarely-tagged songs first, or just go in library order?
- Any way to apply a tag to multiple songs at once (batch tagging), or strictly one song at a time?

## Source of Songs

**v1 scope: offline/local songs only.** The app filters and plays from a local library (files already on-device). Streaming/import from YouTube playlists or other platforms (Spotify, SoundCloud, etc.) is deferred to a later version.

- YouTube support, when added, would use the official IFrame Player API + YouTube Data API to pull playlist contents and play through YouTube's embedded player — not raw audio extraction, which violates YouTube's ToS. This likely means YouTube-sourced tracks play through a separate embedded player rather than the app's own audio engine, so tag filtering may apply to queueing/selection but not to low-level playback control.
- Other platforms would need their own evaluation of what their APIs/ToS allow.

## Data Model

### Song
- `tags`: a free-form set of strings attached to the song (e.g. `family-road-trip`, `workout`, `chill`, `explicit`, `drake`). Tags are user-defined, not a fixed taxonomy — any label can become a tag.
- **Storage (v1): written into the song file's own metadata** (e.g. an ID3-style field on the audio file itself), not a separate database. Tags travel with the file and survive being moved/copied outside the app; the app reads/writes that metadata field directly when tagging or filtering.

## Feature: Tag Filter Switches

**Status: placeholder.** The count (6) and which tags they're bound to are both placeholders for now — the mechanic below is the part that's settled; the specific tags/bindings are not.

### Mechanic

Each switch is bound to one tag. Each switch has three positions:

| Position | Effect |
|---|---|
| **Require** (on) | Only songs carrying this tag are eligible. |
| **Neutral** (middle, default) | This tag has no effect on eligibility. |
| **Exclude** (off) | Songs carrying this tag are removed from eligibility. |

Example from the "Drake" case: Require → only Drake songs; Neutral → doesn't matter if it's Drake or not; Exclude → no Drake songs.

### Combining switches

All switches apply simultaneously as an AND across independent constraints:

- A song is eligible only if it has **every** tag whose switch is set to Require, **and** has **none** of the tags whose switch is set to Exclude.
- Switches set to Neutral impose no constraint.

### Open questions (not yet decided)

- What happens when the active combination of switches matches zero songs — empty playlist, or relax something automatically?
- Is a switch's tag binding fixed per switch, or does the user pick/change which tag each switch controls?
- Is there a path to more than 6 switches, or is 6 a hard UI limit?
- Can a song carry multiple tags that represent the same "category" (e.g. two mood tags at once), and does that matter for filtering?

## Status

Early planning. Spec sheet in progress.
