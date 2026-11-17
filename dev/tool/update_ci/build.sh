#!/usr/bin/env bash
set -euo pipefail

os="$1"
root="$(cd "$(dirname "$0")/../../.." && pwd)"
lab="${UPDATE_LAB:-$root/lab}"
port="${UPDATE_LAB_PORT:-47821}"
base="http://127.0.0.1:$port"
# The Tauri CLI is used only as the minisign tool that signs the Flutter update files with a throwaway key.
signer="npx --yes @tauri-apps/cli@${TAURI_CLI_VERSION:-2.12.3} signer"
mkdir -p "$lab/dist" "$lab/manifests"
cd "$root"

$signer generate --ci --password lab --write-keys "$lab/lab.key" --force > /dev/null
pub="$(cat "$lab/lab.key.pub")"

(cd app && flutter pub get && dart run slang)

if [ "$os" = linux ]; then
  mkdir -p tools
  curl -fsSL -o tools/appimagetool "$APPIMAGETOOL_URL"
  echo "$APPIMAGETOOL_SHA256  tools/appimagetool" | sha256sum -c -
  curl -fsSL -o tools/runtime-x86_64 "$APPIMAGE_RUNTIME_URL"
  echo "$APPIMAGE_RUNTIME_SHA256  tools/runtime-x86_64" | sha256sum -c -
  chmod +x tools/appimagetool
fi

for version in 1.9.0 1.9.1; do
  out="$lab/dist/$version"
  mkdir -p "$out"
  (cd app && flutter build "$os" --release \
    --dart-define=APP_VERSION="$version" \
    --dart-define=UPDATER_TEST_ENDPOINT="$base/latest-v2.json" \
    --dart-define=UPDATER_TEST_PUBKEY="$pub" \
    --dart-define=UPDATER_LAB_AUTO=true \
    --build-name="$version" --build-number=1)
  if [ "$os" = linux ]; then
    bash app/packaging/linux/package.sh app/build/linux/x64/release/bundle "$version" "$out" \
      "$PWD/tools/appimagetool" "$PWD/tools/runtime-x86_64"
  else
    bash app/packaging/macos/package.sh app/build/macos/Build/Products/Release/GodotHub.app "$version" "$out"
  fi
  shopt -s nullglob
  for artifact in "$out"/*.app.tar.gz "$out"/*.AppImage "$out"/*.deb "$out"/*.rpm; do
    TAURI_SIGNING_PRIVATE_KEY_PASSWORD=lab $signer sign --private-key-path "$lab/lab.key" "$artifact" > /dev/null
  done
  shopt -u nullglob
done

if [ "$os" = linux ]; then
  required=linux-x86_64,linux-x86_64-appimage,linux-x86_64-deb,linux-x86_64-rpm
else
  required=darwin-aarch64-flutter,darwin-x86_64-flutter,darwin-universal-flutter
fi
RELEASE_TAG=v1.9.1 REPO=lab/lab ASSETS_DIR="$lab/dist/1.9.1" OUT="$lab/manifests/1.9.1.json" \
  BASE_URL="$base/1.9.1" REQUIRED_PLATFORMS="$required" node app/packaging/release/latest_json.mjs

ls -R "$lab/dist" "$lab/manifests"
