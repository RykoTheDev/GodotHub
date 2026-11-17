#!/usr/bin/env bash
set -euo pipefail

version="$1"
release_dir="$2"
out_dir="$3"
: "${MAKENSIS:?set MAKENSIS to makensis.exe}"
: "${NSIS_PLUGIN_DIR:?set NSIS_PLUGIN_DIR to the folder with ApplicationID.dll}"
: "${WIX_DIR:?set WIX_DIR to the WiX 3 binaries folder}"

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
win() { cygpath -aw "$1"; }

identifier=Ryko.GodotHub
display_name=GodotHub
binary=godothub
slug="$display_name"
exe="$binary.exe"
icon="$root/app/windows/runner/resources/app_icon.ico"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stage="$work/app"
cp -a "$release_dir" "$stage"
if [ ! -f "$stage/$exe" ]; then
  built=$(find "$stage" -maxdepth 1 -name 'godothub*.exe' | head -n 1)
  [ -n "$built" ] || { echo "no GodotHub executable in $release_dir" >&2; exit 1; }
  mv "$built" "$stage/$exe"
fi
output=$("$stage/$exe" --version | tr -d '\r')
[ "$output" = "$binary $version" ] || { echo "the packaged binary reports '$output', expected '$binary $version'" >&2; exit 1; }

(cd "$root" && GODOTHUB_VERSION="$version" cargo build -q -p godothub_launcher --release --locked)
target_dir=$(cd "$root" && cargo metadata --format-version 1 --no-deps | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).target_directory))')
launcher="$target_dir/release/godothub-launcher.exe"
node "$here/check_runtime_imports.mjs" "$stage" "$launcher"

mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
tar="$SYSTEMROOT/System32/tar.exe"
entries=()
for path in "$stage"/*; do entries+=("$(basename "$path")"); done

# One zip serves as both the portable download and the in-app update payload.
zip="$out_dir/$slug-$version-windows-x64-portable.zip"
rm -f "$zip"
(cd "$stage" && "$tar" -a -c -f "$(win "$zip")" "${entries[@]}")

nsis_defines=(
  -DVERSION="$version"
  -DSOURCE_DIR="$(win "$stage")"
  -DOUTFILE="$(win "$out_dir")\\$slug-$version-windows-x64-setup.exe"
  -DIDENTIFIER="$identifier"
  -DDISPLAY_NAME="$display_name"
  -DEXE_NAME="$exe"
  -DICON="$(win "$icon")"
  -DPLUGIN_DIR="$(win "$NSIS_PLUGIN_DIR")"
  -DLAUNCHER="$(win "$launcher")"
  -DPUBLISHER=Rykode
  -DUNINSTALL_NAME=GodotHub
  '-DAPP_KEY_PARENT=Software\GodotHub'
  '-DAPP_KEY=Software\GodotHub\GodotHub'
  -DAPP_KEY_VALUE=
  -DDESKTOP_SHORTCUT
)
"$MAKENSIS" -V2 "${nsis_defines[@]}" "$(win "$here/installer.nsi")"

wix_vars=(
  -dVersion="$version"
  -dProductName="$display_name"
  -dManufacturer=Rykode
  -dUpgradeCode='{72724A70-2A9C-59CB-9DD8-EC8EB8DE6CC5}'
  -dIdentifier="$identifier"
  -dExeName="$exe"
  '-dAppKey=Software\GodotHub\GodotHub'
  -dIcon="$(win "$icon")"
  -dSourceDir="$(win "$stage")"
)
"$WIX_DIR/heat.exe" dir "$(win "$stage")" -nologo -cg AppFiles -dr INSTALLDIR -srd -gg -sfrag -sreg -var var.SourceDir -out "$(win "$work/files.wxs")"
"$WIX_DIR/candle.exe" -nologo -arch x64 "${wix_vars[@]}" -out "$(win "$work")\\" "$(win "$here/msi.wxs")" "$(win "$work/files.wxs")"
"$WIX_DIR/light.exe" -nologo -ext WixUIExtension -sice:ICE57 -sice:ICE91 -spdb \
  -out "$(win "$out_dir")\\$slug-$version-windows-x64.msi" "$(win "$work/msi.wixobj")" "$(win "$work/files.wixobj")"

ls -1 "$out_dir"
