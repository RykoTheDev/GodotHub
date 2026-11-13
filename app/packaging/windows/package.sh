#!/usr/bin/env bash
set -euo pipefail

channel="$1"
version="$2"
release_dir="$3"
out_dir="$4"
: "${MAKENSIS:?set MAKENSIS to makensis.exe}"
: "${NSIS_PLUGIN_DIR:?set NSIS_PLUGIN_DIR to the folder with ApplicationID.dll}"

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
win() { cygpath -aw "$1"; }

info=$(cd "$root" && cargo run -q --locked -p godothub_core --example channel_info -- "$channel")
field() { node -e 'console.log(JSON.parse(process.argv[1])[process.argv[2]])' "$info" "$1"; }
identifier=$(field identifier)
display_name=$(field display_name)
binary=$(field cli_shim_name)
slug="${display_name// /-}"
exe="$binary.exe"

if [ "$channel" = stable ]; then
  icon="$root/app/windows/runner/resources/app_icon_stable.ico"
else
  icon="$root/app/windows/runner/resources/app_icon.ico"
fi

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

(cd "$root" && GODOTHUB_CHANNEL="$channel" cargo build -q -p godothub_launcher --release --locked)
target_dir=$(cd "$root" && cargo metadata --format-version 1 --no-deps | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).target_directory))')
launcher="$target_dir/release/godothub-launcher.exe"

mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
tar="$SYSTEMROOT/System32/tar.exe"
entries=()
for path in "$stage"/*; do entries+=("$(basename "$path")"); done

inapp="$out_dir/$slug-$version-windows-x64.zip"
rm -f "$inapp"
(cd "$stage" && "$tar" -a -c -f "$(win "$inapp")" "${entries[@]}")

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
)
if [ "$channel" = stable ]; then
  nsis_defines+=(
    -DPUBLISHER=GodotHub
    -DUNINSTALL_NAME=GodotHub
    '-DAPP_KEY_PARENT=Software\GodotHub'
    '-DAPP_KEY=Software\GodotHub\GodotHub'
    -DAPP_KEY_VALUE=
    -DDESKTOP_SHORTCUT
  )
fi
"$MAKENSIS" -V2 "${nsis_defines[@]}" "$(win "$here/installer.nsi")"

if [ "$channel" = stable ]; then
  : "${WIX_DIR:?set WIX_DIR to the WiX 3 binaries folder}"
  portable="$out_dir/$slug-$version-windows-x64-portable.zip"
  rm -f "$portable"
  (cd "$stage" && "$tar" -a -c -f "$(win "$portable")" "${entries[@]}")

  wix_vars=(
    -dVersion="$version"
    -dProductName="$display_name"
    -dManufacturer=GodotHub
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
fi

ls -1 "$out_dir"
