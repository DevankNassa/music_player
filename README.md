# Instant Playlist

A music player that builds playlists on the fly based on rules you set — language, explicit content, mood, genre, and more.

## Build

Release APK (signed, for installing on a device):

```
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Requires `android/key.properties` and the release keystore it points to (both
git-ignored — see `android/app/build.gradle.kts`). Without them, release
builds fall back to the debug signing key.

## Status

Early planning. Spec sheet in progress.

## Run app
flutter run -d linux

## Install on Linux

```
./scripts/install-linux.sh
```

Builds a release, installs it to `~/.local/share/insta-playlist`, and adds an
"Instant Playlist" app launcher entry and an `insta-playlist` command. Re-run it
to update. Needs `zenity` (file dialogs) and the GStreamer plugins
(`gst-plugins-good`, `gst-libav`) for playback.
