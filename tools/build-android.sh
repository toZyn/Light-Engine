#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${LOVE_ANDROID_DIR:?Set LOVE_ANDROID_DIR to a love-android 11.5a checkout}"
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
BOON="${BOON:-boon}"

if [[ -z "$SDK" ]]; then
  echo "Set ANDROID_SDK_ROOT or ANDROID_HOME." >&2
  exit 1
fi

LOVE_SRC="$TEMPLATE/love/src/jni/love"
PATCH="$ROOT/android/allow-android-media-mount.patch"

if git -C "$LOVE_SRC" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
  echo "Android media mount patch is already applied."
elif git -C "$LOVE_SRC" apply --check "$PATCH" >/dev/null 2>&1; then
  git -C "$LOVE_SRC" apply "$PATCH"
else
  echo "Could not apply the Android media mount patch." >&2
  exit 1
fi

install -m 0644 "$ROOT/android/StoragePermissionActivity.java" \
  "$TEMPLATE/love/src/main/java/org/love2d/android/StoragePermissionActivity.java"
install -m 0644 "$ROOT/android/AndroidManifest.xml" \
  "$TEMPLATE/app/src/main/AndroidManifest.xml"
install -m 0644 "$ROOT/android/gradle.properties.example" \
  "$TEMPLATE/gradle.properties"

rm -rf "$ROOT/release"
"$BOON" build "$ROOT" --target love --version 11.5
if command -v advzip >/dev/null 2>&1; then
  advzip -z -4 -i 5 "$ROOT/release/Light Engine.love"
fi
install -m 0644 "$ROOT/release/Light Engine.love" \
  "$TEMPLATE/app/src/embed/assets/game.love"

ANDROID_SDK_ROOT="$SDK" ANDROID_HOME="$SDK" \
  "$TEMPLATE/gradlew" -p "$TEMPLATE" :app:assembleEmbedNoRecordRelease --no-daemon

echo "Unsigned APK:"
echo "$TEMPLATE/app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release-unsigned.apk"
