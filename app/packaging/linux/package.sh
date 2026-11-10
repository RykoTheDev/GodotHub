#!/usr/bin/env bash
set -euo pipefail

bundle_dir="$1"
version="$2"
out_dir="$3"
identifier="$4"
display_name="$5"
binary="$6"
icon="$7"
appimagetool="$8"
runtime="$9"

if [ ! -x "$bundle_dir/$binary" ]; then
  echo "missing $bundle_dir/$binary" >&2
  exit 1
fi

slug="${display_name// /-}"
appdir=$(mktemp -d)/AppDir
trap 'rm -rf "$(dirname "$appdir")"' EXIT
mkdir -p "$appdir/usr/bin" "$appdir/usr/share/applications" "$appdir/usr/share/icons/hicolor/256x256/apps"
cp -a "$bundle_dir/." "$appdir/usr/bin/"

cat > "$appdir/$identifier.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$display_name
Exec=$binary %U
Icon=$identifier
Categories=Development;
StartupWMClass=$identifier
Terminal=false
EOF
cp "$appdir/$identifier.desktop" "$appdir/usr/share/applications/$identifier.desktop"
cp "$icon" "$appdir/$identifier.png"
cp "$icon" "$appdir/usr/share/icons/hicolor/256x256/apps/$identifier.png"
ln -s "$identifier.png" "$appdir/.DirIcon"

cat > "$appdir/AppRun" <<EOF
#!/bin/sh
here="\$(dirname "\$(readlink -f "\$0")")"
exec "\$here/usr/bin/$binary" "\$@"
EOF
chmod +x "$appdir/AppRun"

mkdir -p "$out_dir"
appimage="$slug-$version-linux-amd64.AppImage"
zip_name="$appimage.zip"
work=$(mktemp -d)
ARCH=x86_64 "$appimagetool" --appimage-extract-and-run --no-appstream --runtime-file "$runtime" "$appdir" "$work/$appimage"
chmod +x "$work/$appimage"
rm -f "$out_dir/$zip_name"
(cd "$work" && zip -9 -X "$zip_name" "$appimage")
mv "$work/$zip_name" "$out_dir/$zip_name"
rm -rf "$work"

if find "$out_dir" -maxdepth 1 -iname '*.appimage' | grep -q .; then
  echo "a plain AppImage ended up in $out_dir" >&2
  exit 1
fi

echo "$out_dir/$zip_name"
