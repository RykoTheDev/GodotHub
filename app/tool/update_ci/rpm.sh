#!/usr/bin/env bash
set -uo pipefail

dnf install -y -q xorg-x11-server-Xvfb gtk3 webkit2gtk4.1 libappindicator-gtk3 mesa-dri-drivers procps-ng sudo > /dev/null
printf '#!/bin/sh\nexec "$@"\n' > /usr/local/bin/pkexec
chmod +x /usr/local/bin/pkexec

checks=/lab/results/rpm-checks.txt
report=/root/godothub-updater-lab.txt
data=/root/.local/share/Ryko.GodotHub
failures=0
: > "$checks"
note() { echo "$*" | tee -a "$checks"; }
check() { local what="$1"; shift; if "$@"; then note "ok   $what"; else note "FAIL $what"; failures=$((failures + 1)); fi; }
started() {
  for _ in $(seq 1 150); do grep -q "^started $1" "$report" 2>/dev/null && return 0; sleep 2; done
  return 1
}
version() { rpm -q --qf '%{VERSION}' godot-hub 2>/dev/null; }
seed() { rm -f "$report"; mkdir -p "$data"; echo kept > "$data/ci-marker.txt"; }
kept() { [ "$(cat "$data/ci-marker.txt")" = kept ]; }
stop() { pkill -f '/usr/lib/godothub/' ; pkill -x godothub; sleep 3; rpm -e godot-hub > /dev/null 2>&1 || true; }

export DISPLAY=:99
Xvfb :99 -screen 0 1600x1000x24 > /dev/null 2>&1 &
sleep 2

note "===== Flutter rpm 1.9.0 to 1.9.1 in-app (pkexec shim, running as root)"
seed
rpm -i --nodeps /lab/dist/1.9.0/*.rpm
nohup godothub > /lab/results/rpm-app.log 2>&1 &
check '1.9.0 started' started 1.9.0
check '1.9.1 started after the in-app update' started 1.9.1
check "the installed package is 1.9.1 ($(version))" test "$(version)" = 1.9.1
check 'data kept' kept
cp "$report" /lab/results/report-rpm.txt 2>/dev/null
stop

note "===== Tauri 1.5.9 rpm to Flutter through the Tauri updater"
seed
rpm -i --nodeps /lab/tauri/tauri.rpm
check "Tauri rpm installed ($(version))" test "$(version)" = 1.5.9
nohup godothub > /lab/results/rpm-tauri.log 2>&1 &
check 'Flutter 1.9.1 started after the Tauri updater installed it' started 1.9.1
check "the installed package is 1.9.1 ($(version))" test "$(version)" = 1.9.1
check 'data kept' kept
cp "$report" /lab/results/report-tauri-rpm.txt 2>/dev/null
stop

exit "$failures"
