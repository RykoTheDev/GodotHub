#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/common.sh"

data="$HOME/.local/share/Ryko.GodotHub"
apps="$HOME/Applications"
mkdir -p "$apps"
export DISPLAY=:99
Xvfb :99 -screen 0 1600x1000x24 > "$results/xvfb.log" 2>&1 &
xvfb_pid=$!
sleep 2

seed() {
  rm -f "$report"
  mkdir -p "$data"
  echo kept > "$data/ci-marker.txt"
}
kept() { [ "$(cat "$data/ci-marker.txt" 2>/dev/null)" = kept ]; }
stop_apps() {
  pkill -f '/usr/lib/godothub/' 2>/dev/null
  pkill -f 'GodotHub.AppImage' 2>/dev/null
  pkill -f '/usr/bin/godothub' 2>/dev/null
  pkill -x godothub 2>/dev/null
  sleep 3
}
remove_deb() { sudo apt-get remove -y godot-hub > /dev/null 2>&1 || true; }
launch() { nohup "$@" >> "$results/apps.log" 2>&1 & }
appimage_version() { "$apps/GodotHub.AppImage" --appimage-extract-and-run --version 2>/dev/null; }
deb_version() { dpkg-query -W -f '${Version}' godot-hub 2>/dev/null; }

serve 1.9.1

note "===== Flutter AppImage 1.9.0 to 1.9.1 in-app"
stop_apps; seed
cp "$lab"/dist/1.9.0/*.AppImage "$apps/GodotHub.AppImage" && chmod +x "$apps/GodotHub.AppImage"
launch "$apps/GodotHub.AppImage"
check '1.9.0 started' started 1.9.0 180
check '1.9.1 started after the in-app update' started 1.9.1
check "the AppImage is now 1.9.1 ($(appimage_version))" test "$(appimage_version)" = 'godothub 1.9.1'
check 'data kept' kept
save_report appimage
stop_apps; rm -f "$apps/GodotHub.AppImage"

note "===== Flutter deb 1.9.0 to 1.9.1 in-app (pkexec)"
seed
sudo apt-get install -y "$(ls "$lab"/dist/1.9.0/*.deb)" > /dev/null
launch godothub
check '1.9.0 started' started 1.9.0 180
check '1.9.1 started after the in-app update' started 1.9.1
check "the installed package is 1.9.1 ($(deb_version))" test "$(deb_version)" = 1.9.1
check 'data kept' kept
save_report deb
stop_apps; remove_deb

note "===== Tauri 1.5.9 deb to Flutter through the Tauri updater"
seed
sudo apt-get install -y "$lab/tauri/tauri.deb" > /dev/null
check "Tauri deb installed ($(deb_version))" test "$(deb_version)" = 1.5.9
launch godothub
check 'Flutter 1.9.1 started after the Tauri updater installed it' started 1.9.1 300
check "the installed package is 1.9.1 ($(deb_version))" test "$(deb_version)" = 1.9.1
check 'data kept' kept
save_report tauri-deb
stop_apps; remove_deb

note "===== Tauri 1.5.9 AppImage to Flutter AppImage through the Tauri updater"
seed
cp "$lab/tauri/tauri.AppImage" "$apps/GodotHub.AppImage" && chmod +x "$apps/GodotHub.AppImage"
launch "$apps/GodotHub.AppImage"
check 'Flutter 1.9.1 started after the Tauri updater replaced the AppImage' started 1.9.1 300
check "the AppImage is now 1.9.1 ($(appimage_version))" test "$(appimage_version)" = 'godothub 1.9.1'
check 'data kept' kept
save_report tauri-appimage
stop_apps

note "===== rpm paths in a Fedora container"
rm -f "$report"
docker run --rm -v "$lab:/lab" -v "$root:/repo:ro" --network host fedora:41 bash /repo/dev/tool/update_ci/rpm.sh > "$results/rpm.log" 2>&1
rpm_code=$?
cat "$lab/results/rpm-checks.txt" 2>/dev/null | tee -a "$results/checks.txt"
check 'rpm scenarios pass' test "$rpm_code" = 0

kill "$xvfb_pid" 2>/dev/null
finish
