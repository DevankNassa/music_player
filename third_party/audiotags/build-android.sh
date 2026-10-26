#!/usr/bin/env bash
# Rebuilds android/src/main/jniLibs/*/libaudiotags.so (and android.tar.gz,
# which CMakeLists.txt extracts from) from the vendored rust/ source.
#
# Patched in: upstream's prebuilt v1.4.5 libraries use 4 KB ELF page
# alignment, which Google Play rejects for apps targeting Android 15+
# (16 KB page size requirement).
#
# Needs rustup (for the Android std targets) and the Android NDK. Usage:
#   ANDROID_NDK_HOME=~/Android/Sdk/ndk/<version> ./build-android.sh
set -euo pipefail
cd "$(dirname "$0")"

: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to an NDK (r28+)}"
API=24
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
export RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384"

# rust target : NDK clang prefix : Android ABI directory
TARGETS=(
  "aarch64-linux-android:aarch64-linux-android:arm64-v8a"
  "armv7-linux-androideabi:armv7a-linux-androideabi:armeabi-v7a"
  "x86_64-linux-android:x86_64-linux-android:x86_64"
  "i686-linux-android:i686-linux-android:x86"
)

for entry in "${TARGETS[@]}"; do
  IFS=: read -r target clang abi <<< "$entry"
  rustup target add "$target"
  env_target=$(echo "$target" | tr 'a-z-' 'A-Z_')
  export "CARGO_TARGET_${env_target}_LINKER=$TOOLCHAIN/${clang}${API}-clang"
  export "CARGO_TARGET_${env_target}_AR=$TOOLCHAIN/llvm-ar"
  # For dependencies that compile C code (via the cc crate).
  export "CC_${target//-/_}=$TOOLCHAIN/${clang}${API}-clang"
  export "AR_${target//-/_}=$TOOLCHAIN/llvm-ar"
  cargo build --release --lib --target "$target" --manifest-path rust/Cargo.toml
  mkdir -p "android/src/main/jniLibs/$abi"
  "$TOOLCHAIN/llvm-strip" -o "android/src/main/jniLibs/$abi/libaudiotags.so" \
    "rust/target/$target/release/libaudiotags.so"
done

tar -czf android/android.tar.gz -C android/src/main/jniLibs .
