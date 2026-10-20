# Insta-Playlist

A music player that builds playlists on the fly based on rules you set — language, explicit content, mood, genre, and more. Working name, subject to change.

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
