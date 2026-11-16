#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/common.sh"

apps="$HOME/Applications"
app="$apps/GodotHub.app"
data="$HOME/Library/Application Support/Ryko.GodotHub"
mkdir -p "$apps"

seed() {
  rm -f "$report"
  mkdir -p "$data"
  echo kept > "$data/ci-marker.txt"
}
kept() { [ "$(cat "$data/ci-marker.txt" 2>/dev/null)" = kept ]; }
stop_apps() { pkill -f 'GodotHub.app/Contents/MacOS/' 2>/dev/null; sleep 3; }
bundle_version() { /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null; }

serve 1.9.1

note "===== Flutter app 1.9.0 to 1.9.1 in-app (bundle swap)"
stop_apps; seed; rm -rf "$app"
tar -xzf "$(ls "$lab"/dist/1.9.0/*.app.tar.gz)" -C "$apps"
nohup "$app/Contents/MacOS/GodotHub" >> "$results/apps.log" 2>&1 &
sleep 30
pgrep -fl 'GodotHub.app/Contents/MacOS/' > "$results/processes.txt" 2>&1
for pid in $(pgrep -f 'GodotHub.app/Contents/MacOS/'); do sample "$pid" 3 -file "$results/sample-$pid.txt" > /dev/null 2>&1; done
check '1.9.0 started' started 1.9.0 180
check '1.9.1 started after the in-app update' started 1.9.1
check "the bundle is now 1.9.1 ($(bundle_version))" test "$(bundle_version)" = 1.9.1
check 'no leftover bundles next to the app' test "$(ls -d "$apps"/*.app | wc -l | tr -d ' ')" = 1
check 'data kept' kept
save_report app
log show --info --debug --style compact --last 8m --predicate 'process == "GodotHub"' > "$results/oslog-app.txt" 2>&1 || true
stop_apps

note "===== Tauri 1.5.9 app is not offered the Flutter build (Macs update by hand)"
seed; rm -rf "$app"
cp -R "$lab/tauri/GodotHub.app" "$app"
check "Tauri app installed ($(bundle_version))" test "$(bundle_version)" = 1.5.9
nohup "$app/Contents/MacOS/GodotHub" >> "$results/apps.log" 2>&1 &
sleep 90
check "the Tauri updater left the bundle alone ($(bundle_version))" test "$(bundle_version)" = 1.5.9
check 'the Tauri app is still running' pgrep -f 'GodotHub.app/Contents/MacOS/GodotHub'
check 'data kept' kept
save_report tauri-app
log show --info --debug --style compact --last 8m --predicate 'process == "GodotHub"' > "$results/oslog-tauri-app.txt" 2>&1 || true
stop_apps

finish
