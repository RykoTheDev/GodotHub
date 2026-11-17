#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$(cd "$here/../../../app" && pwd)"
repo="$(cd "$app/.." && pwd)"
lab="${UPDATE_LAB:-$app/build/update_lab}"
port="${UPDATE_LAB_PORT:-47821}"
base="http://127.0.0.1:$port"
tauri="$repo/node_modules/.bin/tauri.exe"
tools="$app/build/tools"
: "${MAKENSIS:=$tools/nsis-3.13/makensis.exe}"
: "${NSIS_PLUGIN_DIR:=$tools/plugin}"
: "${WIX_DIR:=$tools/wix}"
export MAKENSIS NSIS_PLUGIN_DIR WIX_DIR

mkdir -p "$lab"
[ -f "$lab/lab.key" ] || "$tauri" signer generate --ci --password lab --write-keys "$lab/lab.key" --force
[ -f "$lab/wrong.key" ] || "$tauri" signer generate --ci --password other --write-keys "$lab/wrong.key" --force
pub="$(cat "$lab/lab.key.pub")"

build() {
  local version="$1" crash="${2:-}"
  local out="$lab/dist/$version"
  if [ -z "${REBUILD:-}" ] && [ -f "$out/GodotHub-$version-windows-x64-setup.exe" ]; then
    echo "$version already built"
    return
  fi
  echo "building $version"
  (cd "$app" && flutter build windows --release \
    --dart-define=CHANNEL=stable \
    --dart-define=APP_VERSION="$version" \
    --dart-define=UPDATER_TEST_ENDPOINT="$base/latest-v2.json" \
    --dart-define=UPDATER_TEST_PUBKEY="$pub" \
    ${crash:+--dart-define=UPDATER_LAB_CRASH=true} \
    --build-name="$version" --build-number=1 > "$lab/build-$version.log" 2>&1)
  rm -rf "$out"
  bash "$app/packaging/windows/package.sh" stable "$version" "$app/build/windows/x64/runner/Release" "$out" > "$lab/package-$version.log" 2>&1
}

sign() {
  local dir="$1" key="$2" password="$3"
  rm -f "$dir"/*.sig
  for file in "$dir"/*-setup.exe "$dir"/*.msi "$dir"/*-windows-x64-portable.zip; do
    [ -f "$file" ] || continue
    TAURI_SIGNING_PRIVATE_KEY_PASSWORD="$password" "$tauri" signer sign --private-key-path "$key" "$file" > /dev/null
  done
}

manifest() {
  local version="$1" dir="$2" out="$3" required="$4"
  CHANNEL=stable RELEASE_TAG="v$version" REPO=lab/lab ASSETS_DIR="$dir" OUT="$out" BASE_URL="$base/$version" \
    REQUIRED_PLATFORMS="$required" node "$app/packaging/release/latest_json.mjs"
}

build 1.9.0
build 1.9.1
build 1.9.2 crash

all=windows-x86_64,windows-x86_64-nsis,windows-x86_64-msi,windows-x86_64-inapp
mkdir -p "$lab/manifests"
for version in 1.9.0 1.9.1 1.9.2; do
  sign "$lab/dist/$version" "$lab/lab.key" lab
done
manifest 1.9.1 "$lab/dist/1.9.1" "$lab/manifests/1.9.1.json" "$all"
manifest 1.9.2 "$lab/dist/1.9.2" "$lab/manifests/1.9.2-crash.json" "$all"

wrong="$lab/dist/wrong-1.9.1"
rm -rf "$wrong" && mkdir -p "$wrong"
cp "$lab/dist/1.9.1"/*-setup.exe "$lab/dist/1.9.1"/*.msi "$lab/dist/1.9.1"/*-windows-x64-portable.zip "$wrong/"
sign "$wrong" "$lab/wrong.key" other
manifest 1.9.1 "$wrong" "$lab/manifests/1.9.1-wrong-key.json" "$all"
rm -rf "$wrong"

tauri_dir="$repo/src-tauri/target/release/bundle"
mkdir -p "$lab/tauri"
cp "$tauri_dir"/nsis/GodotHub_1.5.9_x64-setup.exe "$lab/tauri/tauri-setup.exe"
cp "$tauri_dir"/msi/GodotHub_1.5.9_x64_en-US.msi "$lab/tauri/tauri.msi"
cp "$here"/*.ps1 "$here"/../data_sandbox/UiaCom.cs "$lab/"
cp -r "$app/build/data_lab/datasets/backup" "$lab/backup" 2>/dev/null || true
find "$lab/backup" \( -name git-credentials -o -name git_auth.json \) -delete 2>/dev/null || true
echo "update lab ready in $lab"
