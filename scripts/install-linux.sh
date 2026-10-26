#!/usr/bin/env bash
# Builds the Linux release and installs it for the current user, with a
# desktop entry so it shows up in the app launcher. Re-run to update.
set -euo pipefail

cd "$(dirname "$0")/.."

app_id=com.devanknassa.insta_playlist
install_dir="$HOME/.local/share/insta-playlist"
bin_dir="$HOME/.local/bin"
apps_dir="$HOME/.local/share/applications"
icon_dir="$HOME/.local/share/icons/hicolor/1024x1024/apps"

flutter build linux --release

rm -rf "$install_dir"
mkdir -p "$install_dir" "$bin_dir" "$apps_dir" "$icon_dir"
cp -r build/linux/x64/release/bundle/. "$install_dir"
ln -sf "$install_dir/insta_playlist" "$bin_dir/insta-playlist"
cp ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png "$icon_dir/$app_id.png"

# The file name matches the GTK application id so the window gets grouped
# with (and takes the icon of) this entry.
cat > "$apps_dir/$app_id.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Instant Playlist
Comment=Music player that builds playlists from your tags
Exec=$install_dir/insta_playlist
Icon=$app_id
Categories=AudioVideo;Audio;Player;
StartupWMClass=$app_id
Terminal=false
DESKTOP

update-desktop-database "$apps_dir" 2>/dev/null || true
echo "Installed to $install_dir (launcher entry: Instant Playlist, command: insta-playlist)"
