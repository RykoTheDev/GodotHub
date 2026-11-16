#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat <<'EOF'
Checks a stable GodotHub package on a real Linux desktop or Mac, installed over Tauri 1.5.9.

  bash check.sh <folder with the stable packages> [--kind deb|rpm|appimage|app] [--tauri v1.5.9]

The packages come from the stable-linux or stable-macos artifact of the "Flutter Stable Packaging"
workflow. Your GodotHub data folder is backed up first and put back at the end; the checks run on
a copy of it. A report is written to ~/godothub-stable-check-<date>.txt.
EOF
}

[ $# -ge 1 ] || { usage; exit 1; }
dist="$(cd "$1" && pwd)"; shift
kind=""
tauri_tag="v1.5.9"
while [ $# -gt 0 ]; do
  case "$1" in
    --kind) kind="$2"; shift 2 ;;
    --tauri) tauri_tag="$2"; shift 2 ;;
    *) usage; exit 1 ;;
  esac
done

os="$(uname -s)"
stamp="$(date +%Y%m%d-%H%M%S)"
report="$HOME/godothub-stable-check-$stamp.txt"
work="$(mktemp -d)"
failures=0

note() { echo "$*" | tee -a "$report"; }
check() { local what="$1"; shift; if "$@" > /dev/null 2>&1; then note "ok   $what"; else note "FAIL $what"; failures=$((failures + 1)); fi; }
ask() {
  local answer
  read -r -p "$1 [y/n] " answer < /dev/tty
  if [ "$answer" = y ] || [ "$answer" = Y ]; then note "ok   $1 (checked by hand)"; else note "FAIL $1 (checked by hand)"; failures=$((failures + 1)); fi
}
pause() { read -r -p "$1 Press Enter when done. " _ < /dev/tty; }

if [ "$os" = Darwin ]; then
  data="$HOME/Library/Application Support/Ryko.GodotHub"
  kind="app"
  app="/Applications/GodotHub.app"
  exe="$app/Contents/MacOS/GodotHub"
else
  data="${XDG_DATA_HOME:-$HOME/.local/share}/Ryko.GodotHub"
  if [ -z "$kind" ]; then
    if command -v apt-get > /dev/null; then kind=deb
    elif command -v dnf > /dev/null || command -v zypper > /dev/null; then kind=rpm
    else kind=appimage
    fi
  fi
  appimage="$HOME/Applications/GodotHub.AppImage"
fi
backup="$HOME/godothub-data-backup-$stamp"

note "GodotHub stable check, $(date)"
if [ "$os" = Darwin ]; then
  note "system: macOS $(sw_vers -productVersion) on $(uname -m)"
else
  note "system: $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Linux}"), ${XDG_CURRENT_DESKTOP:-unknown desktop}, ${XDG_SESSION_TYPE:-unknown session}"
fi
note "package: $kind from $dist"
note ""

running() { pgrep -f '/usr/lib/godothub/|GodotHub.AppImage|GodotHub.app/Contents/MacOS/' > /dev/null; }
stop_app() {
  pkill -f '/usr/lib/godothub/' 2>/dev/null; pkill -f 'GodotHub.AppImage' 2>/dev/null
  pkill -f 'GodotHub.app/Contents/MacOS/' 2>/dev/null; pkill -x godothub 2>/dev/null
  sleep 3
}
launch() {
  if [ "$os" = Darwin ]; then open "$app"
  elif [ "$kind" = appimage ]; then nohup "$appimage" > "$work/app.log" 2>&1 &
  else nohup godothub > "$work/app.log" 2>&1 &
  fi
  for _ in $(seq 1 30); do running && return 0; sleep 1; done
  return 1
}
version_output() {
  if [ "$os" = Darwin ]; then "$exe" --version 2>/dev/null
  elif [ "$kind" = appimage ]; then "$appimage" --appimage-extract-and-run --version 2>/dev/null
  else godothub --version 2>/dev/null
  fi
}
hash_data() { (cd "$data" 2>/dev/null && find . -type f ! -name '*.bak' ! -name 'git-credentials' ! -name 'git_auth.json' -print0 | sort -z | xargs -0 shasum 2>/dev/null) ; }

stop_app
if [ -d "$data" ]; then
  cp -a "$data" "$backup"
  note "your data was backed up to $backup"
else
  note "no existing GodotHub data; the checks start from an empty profile"
fi

install_tauri() {
  local base="https://github.com/RykoTheDev/GodotHub/releases/download/$tauri_tag"
  case "$kind" in
    app)
      curl -fsSL -o "$work/tauri.tar.gz" "$base/GodotHub-${tauri_tag#v}-darwin-universal.app.tar.gz" || return 1
      rm -rf "$app"; tar -xzf "$work/tauri.tar.gz" -C /Applications ;;
    deb)
      curl -fsSL -o "$work/tauri.deb" "$base/GodotHub-${tauri_tag#v}-linux-amd64.deb" || return 1
      sudo apt-get install -y "$work/tauri.deb" > /dev/null ;;
    rpm)
      curl -fsSL -o "$work/tauri.rpm" "$base/GodotHub-${tauri_tag#v}-linux-x86_64.rpm" || return 1
      if command -v dnf > /dev/null; then sudo dnf install -y "$work/tauri.rpm" > /dev/null; else sudo zypper --non-interactive install --allow-unsigned-rpm "$work/tauri.rpm" > /dev/null; fi ;;
    appimage)
      mkdir -p "$HOME/Applications"
      curl -fsSL -o "$appimage" "$base/GodotHub-${tauri_tag#v}-linux-amd64.AppImage" || return 1
      chmod +x "$appimage" ;;
  esac
}

install_flutter() {
  case "$kind" in
    app)
      rm -rf "$app"; tar -xzf "$(ls "$dist"/*-darwin-universal.app.tar.gz)" -C /Applications ;;
    deb) sudo apt-get install -y "$(ls "$dist"/*-linux-amd64.deb)" > /dev/null ;;
    rpm)
      if command -v dnf > /dev/null; then sudo dnf install -y "$(ls "$dist"/*-linux-x86_64.rpm)" > /dev/null
      else sudo zypper --non-interactive install --allow-unsigned-rpm "$(ls "$dist"/*-linux-x86_64.rpm)" > /dev/null; fi ;;
    appimage) cp "$(ls "$dist"/*-linux-amd64.AppImage)" "$appimage"; chmod +x "$appimage" ;;
  esac
}

note "===== Tauri $tauri_tag"
check "Tauri $tauri_tag installs" install_tauri
check 'Tauri opens' launch
pause 'Use Tauri briefly so it writes its data (open Projects and Settings), then close it.'
stop_app
hash_data > "$work/before.txt"

note ""
note "===== Flutter stable over Tauri"
check 'the stable package installs over Tauri' install_flutter
version="$(version_output)"
check "the installed app reports a stable version ($version)" test -n "$version"
check 'the app opens' launch
sleep 5
second_before="$(pgrep -fc '/usr/lib/godothub/|GodotHub.AppImage|GodotHub.app/Contents/MacOS/' 2>/dev/null || echo 0)"
if [ "$os" = Darwin ]; then "$exe" > /dev/null 2>&1 & else launch > /dev/null; fi
sleep 5
second_after="$(pgrep -fc '/usr/lib/godothub/|GodotHub.AppImage|GodotHub.app/Contents/MacOS/' 2>/dev/null || echo 0)"
check "a second launch does not start a second app ($second_before then $second_after processes)" test "$second_after" -le "$second_before"
if [ "$kind" != appimage ] && [ "$kind" != app ]; then
  check 'the CLI shim answers (godothub versions)' godothub versions
  check 'the desktop file is installed' test -f /usr/share/applications/GodotHub.desktop
  check 'the app icon is installed' sh -c 'ls /usr/share/icons/hicolor/*/apps/godothub.png /usr/share/icons/hicolor/*/apps/Ryko.GodotHub.png 2>/dev/null | grep -q .'
fi
if [ "$os" = Darwin ]; then
  check 'the app is not sandboxed' sh -c "! codesign -d --entitlements - '$app' 2>/dev/null | grep -A1 app-sandbox | grep -q true"
  note "     signature: $(codesign -dv "$app" 2>&1 | grep -E 'Signature|TeamIdentifier' | tr '\n' ' ')"
  xattr -w com.apple.quarantine "0081;$(printf '%x' "$(date +%s)");Safari;" "$app" 2>/dev/null
  note "     Gatekeeper on a downloaded copy: $(spctl -a -vv "$app" 2>&1 | head -1)"
  xattr -dr com.apple.quarantine "$app" 2>/dev/null
fi
note ""
note "Now check these by hand in the Flutter app:"
ask 'Every screen opens and shows your data (Projects, Versions, Templates, Vault, Storage, Asset Store, News, Settings)'
ask 'The window opens where and how big it was (window state), and remembers changes after a restart'
ask 'The tray or menu bar icon is there and its menu works'
ask 'A notification appears (for example after installing or removing a Godot version)'
ask 'File dialogs open (Import a project, pick a folder in Settings)'
ask 'Dragging a project folder onto the window imports it'
[ "$os" = Darwin ] && ask 'The Dock menu shows recent projects and opens them'
[ "$os" = Darwin ] && ask 'The window is not blank after a restart that started maximized'
pause 'Change something visible (pin a project, change the theme), then close the app.'
stop_app
hash_data > "$work/after-flutter.txt"
check 'no data file was lost' sh -c "cut -c43- '$work/before.txt' | while read -r f; do [ -e \"$data/\$f\" ] || exit 1; done"

note ""
note "===== Rollback: Tauri $tauri_tag again on the data Flutter wrote"
if [ "$kind" = deb ]; then sudo apt-get remove -y godot-hub > /dev/null; fi
if [ "$kind" = rpm ]; then sudo rpm -e godot-hub > /dev/null 2>&1; fi
check "Tauri $tauri_tag reinstalls" install_tauri
check 'Tauri opens on the data Flutter wrote' launch
ask "Tauri shows the change you made in the Flutter app (pinned project, theme)"
stop_app

note ""
note "===== Put things back"
if [ -d "$backup" ]; then
  rm -rf "$data"; cp -a "$backup" "$data"
  note "your data was restored from $backup (the backup is kept)"
fi
note "Tauri $tauri_tag is installed again. Install the stable package yourself if you want to keep it."
note ""
note "$failures failure(s); report: $report"
rm -rf "$work"
