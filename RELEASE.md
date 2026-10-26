# Store release checklist

Tracks getting the app onto the Apple App Store and Google Play. Tick items
off (`[x]`) as they're done.

IDs (permanent once published, never shown to users):
- Android application ID: `com.devanknassa.insta_playlist`
- iOS bundle ID: `com.devanknassa.instaPlaylist`

---

## 1. Accounts (start now, verification takes days)

- [ ] **Apple Developer Program**: enroll as an individual at
      https://developer.apple.com/programs/ ($99/year, Apple ID with 2FA).
      Approval usually takes 1–2 days.
- [ ] **Google Play Console**: create a *personal* account at
      https://play.google.com/console ($25 once) and complete ID verification.
- [ ] **Find 12+ Android testers.** New personal Play accounts must run a
      closed test with at least 12 opted-in testers for 14 days in a row
      before they can publish to production. Collect their Gmail addresses.

## 2. Code changes for store compliance

Done:
- [x] Android: drop "All files access" (`MANAGE_EXTERNAL_STORAGE`). Play
      only allows it for file managers, backup apps and similar. Music
      folders are now picked with the system folder picker and kept with a
      persisted grant, and tags are written back through that grant
      (`MusicFolderAccess` in `MainActivity.kt`).
- [x] Android: folders picked earlier are restored on launch, like iOS.
- [x] Android: "+ Add" is folder-only, like iOS. Individually picked
      songs are cache copies on Android, so tags never reached the originals.
- [x] Android: rebuild `libaudiotags.so` with 16 KB page alignment, which
      Play requires for apps targeting Android 15+
      (`third_party/audiotags/build-android.sh`).
- [x] iOS: `ITSAppUsesNonExemptEncryption = false` (skips the export
      compliance question on every upload).
- [x] iOS: iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad
      screenshots or iPad review.
- [x] iOS: privacy manifest `ios/Runner/PrivacyInfo.xcprivacy` (no
      tracking, no data collected, UserDefaults reason `CA92.1`).
- [x] iOS: signed build + TestFlight upload workflow
      (`.github/workflows/ios-release.yml`).
- [x] Privacy policy page: `docs/privacy-policy.md`.

Waiting on decisions:
- [ ] **Final app name.** "Insta" is a Meta trademark, and Apple rejects
      names that imitate another brand (guideline 5.2). Rename everywhere it shows:
      `android:label` in `AndroidManifest.xml`, `CFBundleDisplayName` and
      `CFBundleName` in `ios/Runner/Info.plist`, `MaterialApp.title` in
      `lib/main.dart`, `docs/privacy-policy.md`, and the store listings.
- [x] **App icon.** The "disc + tag" mock (`assets/icon/app_icon.svg`),
      rendered for every platform by `scripts/generate_icons.py`. The
      1024×1024 iOS icon has no transparency, as Apple requires.

## 3. Privacy policy hosting

- [ ] GitHub repo → Settings → Pages → *Deploy from a branch* → `master`,
      folder `/docs`.
- [ ] Check it loads at
      https://devanknassa.github.io/music_player/privacy-policy.html
      (this URL goes in both store listings).

## 4. Android: Google Play

Build:
- [ ] Back up `android/app/insta-playlist-release.keystore` **and**
      `android/key.properties` somewhere off this machine (password manager /
      encrypted drive). With Play App Signing this is the *upload* key, which
      can be reset if lost, but that takes a support request.
- [ ] Bump `version:` in `pubspec.yaml` for every upload (the `+N` build
      number must always increase).
- [ ] `flutter build appbundle --release` →
      `build/app/outputs/bundle/release/app-release.aab`

Play Console → Create app (name, default language, App, Free):
- [ ] **App content** section:
  - [ ] Privacy policy URL (step 3)
  - [ ] App access: all functionality available without special access
  - [ ] Ads: no ads
  - [ ] Content rating questionnaire (category: Utility/Productivity or
        Entertainment; answer no to everything)
  - [ ] Target audience: 13+ (choosing under-13 brings in the Families policy)
  - [ ] Data safety: no data collected, no data shared
  - [ ] Foreground service permissions: declare `mediaPlayback`. It's
        used to keep music playing in the background with a media
        notification. Google asks for a short screen recording of this.
  - [ ] Government / financial / health / news: no
- [ ] **Store listing**: name (≤30 chars), short description (≤80), full
      description (≤4000), icon 512×512, feature graphic 1024×500, at least 2
      phone screenshots, category *Music & Audio*, contact email.
- [ ] **Closed testing** → create track → upload the `.aab` → add the 12+
      testers' emails → share the opt-in link with them.
- [ ] Testers keep it installed for **14 days**.
- [ ] Dashboard → *Apply for production* (answers a short questionnaire
      about the test).
- [ ] Production release → upload `.aab` → roll out. First review usually
      takes a few days.

## 5. iOS: App Store (no Mac needed)

Developer portal (https://developer.apple.com/account):
- [ ] Identifiers → **+** → App IDs → App → Bundle ID (explicit)
      `com.devanknassa.instaPlaylist`. No extra capabilities needed.
- [ ] Create a distribution certificate from Linux:
      ```sh
      mkdir -p ~/ios-signing && cd ~/ios-signing   # keep this folder private
      openssl genrsa -out dist.key 2048
      openssl req -new -key dist.key -out dist.csr \
        -subj "/emailAddress=YOUR_APPLE_ID_EMAIL/CN=Your Name/C=IN"
      ```
      Certificates → **+** → *Apple Distribution* → upload `dist.csr` →
      download `distribution.cer`, then:
      ```sh
      openssl x509 -inform DER -in distribution.cer -out dist.pem
      # -legacy: macOS keychains can't import OpenSSL 3's default .p12 format
      openssl pkcs12 -export -legacy -inkey dist.key -in dist.pem -out dist.p12
      ```
      (Pick a strong export password; it becomes a secret below.)
- [ ] Profiles → **+** → Distribution *App Store Connect* → the app ID →
      the certificate → name it e.g. `Insta Playlist App Store` → download.

App Store Connect (https://appstoreconnect.apple.com):
- [ ] Users and Access → Integrations → App Store Connect API → Team Keys →
      generate a key with role *App Manager*. Note the **Key ID** and
      **Issuer ID**, and download `AuthKey_<id>.p8` (downloadable only once).
- [ ] Apps → **+** New App → iOS, name, language, bundle ID, SKU (any
      string, e.g. `instaplaylist`).
- [ ] Add GitHub secrets (from `~/ios-signing`):
      ```sh
      base64 -w0 dist.p12 | gh secret set IOS_DIST_CERT_P12_BASE64
      gh secret set IOS_DIST_CERT_PASSWORD          # paste the .p12 password
      base64 -w0 *.mobileprovision | gh secret set IOS_PROFILE_BASE64
      gh secret set APPSTORE_KEY_ID                 # paste Key ID
      gh secret set APPSTORE_ISSUER_ID              # paste Issuer ID
      gh secret set APPSTORE_PRIVATE_KEY < AuthKey_*.p8
      ```
- [ ] `gh workflow run ios-release.yml`. The build then appears in
      App Store Connect → TestFlight after processing (~15–30 min).
- [ ] Install it via TestFlight on the iPhone and smoke-test (pick the
      Syncthing folder, play, tag a song, check the tag synced).

Listing and submission:
- [ ] App Privacy → *Data Not Collected*.
- [ ] Age rating questionnaire (all "none" → 4+).
- [ ] Pricing and availability: Free, countries.
- [ ] EU Digital Services Act trader status (declare *not a trader* if you
      don't earn money from it; traders must publish an address and phone).
- [ ] Version page: screenshots for the 6.9" iPhone display (1320×2868 or
      1290×2796, at least 1), promotional text, description, keywords
      (≤100 chars), support URL (the GitHub repo is fine), privacy policy URL,
      category *Music*.
- [ ] Review notes. Explain that the app plays the user's own files and how
      to test it: "Copy a few audio files into Files → On My iPhone →
      <app name>, then tap + Add and choose that folder." Consider linking a
      short demo video.
- [ ] Select the TestFlight build → *Add for Review* → submit. Review
      usually takes 1–3 days.

## 6. After launch

- [ ] Every update: bump `version:` in `pubspec.yaml`, build the `.aab`
      for Play, run `ios-release.yml` for iOS (the build number is set
      automatically there).
- [ ] Keep `~/ios-signing` and the Android keystore backed up. The Apple
      distribution certificate expires after 1 year; renew it and update the
      two `IOS_DIST_CERT_*` secrets and the profile.
