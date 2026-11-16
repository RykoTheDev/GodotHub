#!/usr/bin/env bash
set -euo pipefail

os="$1"
root="$(cd "$(dirname "$0")/../../.." && pwd)"
lab="${UPDATE_LAB:-$root/lab}"
port="${UPDATE_LAB_PORT:-47821}"
base="http://127.0.0.1:$port"
tauri="npx --yes @tauri-apps/cli@${TAURI_CLI_VERSION:-2.12.3}"
mkdir -p "$lab/dist" "$lab/manifests" "$lab/tauri"
cd "$root"

$tauri signer generate --ci --password lab --write-keys "$lab/lab.key" --force > /dev/null
pub="$(cat "$lab/lab.key.pub")"
info=$(cargo run -q --locked -p godothub_core --example channel_info -- stable)
id=$(jq -r .identifier <<<"$info")
name=$(jq -r .display_name <<<"$info")
bin=$(jq -r .cli_shim_name <<<"$info")

(cd app && flutter pub get && dart run tool/i18n_convert.dart && dart run slang)
if [ "$os" = macos ]; then
  bash app/packaging/macos/use_channel.sh stable "$id" "$name"
fi

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
    --dart-define=CHANNEL=stable \
    --dart-define=APP_VERSION="$version" \
    --dart-define=UPDATER_TEST_ENDPOINT="$base/latest-v2.json" \
    --dart-define=UPDATER_TEST_PUBKEY="$pub" \
    --dart-define=UPDATER_LAB_AUTO=true \
    --build-name="$version" --build-number=1)
  if [ "$os" = linux ]; then
    bash app/packaging/linux/package.sh stable app/build/linux/x64/release/bundle "$version" "$out" "$id" "$name" "$bin" \
      app/packaging/icons/stable/app_icon.png "$PWD/tools/appimagetool" "$PWD/tools/runtime-x86_64"
  else
    bash app/packaging/macos/package.sh "app/build/macos/Build/Products/Release/$name.app" "$version" "$out" "$id" "$name"
  fi
  shopt -s nullglob
  for artifact in "$out"/*.app.tar.gz "$out"/*.AppImage "$out"/*.deb "$out"/*.rpm; do
    TAURI_SIGNING_PRIVATE_KEY_PASSWORD=lab $tauri signer sign --private-key-path "$lab/lab.key" "$artifact" > /dev/null
  done
  shopt -u nullglob
done

if [ "$os" = linux ]; then
  required=linux-x86_64,linux-x86_64-appimage,linux-x86_64-deb,linux-x86_64-rpm
else
  required=darwin-aarch64-flutter,darwin-x86_64-flutter,darwin-universal-flutter
fi
CHANNEL=stable RELEASE_TAG=v1.9.1 REPO=lab/lab ASSETS_DIR="$lab/dist/1.9.1" OUT="$lab/manifests/1.9.1.json" \
  BASE_URL="$base/1.9.1" REQUIRED_PLATFORMS="$required" node app/packaging/release/latest_json.mjs

cat app/tool/update_ci/tauri-auto-update.ts >> src/main.tsx
if [ "$os" = linux ]; then targets='["appimage","deb","rpm"]'; else targets='["app"]'; fi
node -e '
const [pub, base, targets, out] = process.argv.slice(1)
require("fs").writeFileSync(out, JSON.stringify({
  version: "1.5.9",
  bundle: { targets: JSON.parse(targets), createUpdaterArtifacts: true },
  plugins: { updater: { pubkey: pub, endpoints: [`${base}/latest-v2.json`], dangerousInsecureTransportProtocol: true } },
}))' "$pub" "$base" "$targets" "$lab/tauri-test.conf.json"
bun install --frozen-lockfile
TAURI_SIGNING_PRIVATE_KEY="$(cat "$lab/lab.key")" TAURI_SIGNING_PRIVATE_KEY_PASSWORD=lab $tauri build --config "$lab/tauri-test.conf.json"
git checkout -- src/main.tsx
bundle=src-tauri/target/release/bundle
if [ "$os" = linux ]; then
  cp "$bundle"/appimage/*.AppImage "$lab/tauri/tauri.AppImage"
  cp "$bundle"/deb/*.deb "$lab/tauri/tauri.deb"
  cp "$bundle"/rpm/*.rpm "$lab/tauri/tauri.rpm"
else
  cp -R "$bundle"/macos/*.app "$lab/tauri/"
fi
ls -R "$lab/dist" "$lab/tauri" "$lab/manifests"
