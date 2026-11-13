#!/usr/bin/env bash
set -euo pipefail

channel="$1"
bundle_dir="$2"
version="$3"
out_dir="$4"
identifier="$5"
display_name="$6"
binary="$7"
icon="$8"
appimagetool="$9"
runtime="${10}"

built=$(find "$bundle_dir" -maxdepth 1 -type f -name 'godothub*' -perm -u+x | head -n 1)
if [ -z "$built" ]; then
  echo "no GodotHub executable in $bundle_dir" >&2
  exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
bundle="$work/bundle"
cp -a "$bundle_dir/." "$bundle/"
if [ "$(basename "$built")" != "$binary" ]; then
  mv "$bundle/$(basename "$built")" "$bundle/$binary"
fi
output=$("$bundle/$binary" --version)
if [ "$output" != "$binary $version" ]; then
  echo "the packaged binary reports '$output', expected '$binary $version'" >&2
  exit 1
fi

slug="${display_name// /-}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

appdir="$work/AppDir"
mkdir -p "$appdir/usr/bin" "$appdir/usr/share/applications" "$appdir/usr/share/icons/hicolor/256x256/apps"
cp -a "$bundle/." "$appdir/usr/bin/"
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

appimage="$slug-$version-linux-amd64.AppImage"
ARCH=x86_64 "$appimagetool" --appimage-extract-and-run --no-appstream --runtime-file "$runtime" "$appdir" "$work/$appimage"
chmod +x "$work/$appimage"

if [ "$channel" != stable ]; then
  zip_name="$appimage.zip"
  rm -f "$out_dir/$zip_name"
  (cd "$work" && zip -9 -X "$zip_name" "$appimage")
  mv "$work/$zip_name" "$out_dir/$zip_name"
  if find "$out_dir" -maxdepth 1 -iname '*.appimage' | grep -q .; then
    echo "a plain AppImage ended up in $out_dir" >&2
    exit 1
  fi
  echo "$out_dir/$zip_name"
  exit 0
fi

mv "$work/$appimage" "$out_dir/$appimage"
echo "$out_dir/$appimage"

package=godot-hub
summary="Godot Version and Project Management"
root="$work/pkgroot"
mkdir -p "$root/usr/lib/$binary" "$root/usr/bin" "$root/usr/share/applications"
cp -a "$bundle/." "$root/usr/lib/$binary/"
ln -s "../lib/$binary/$binary" "$root/usr/bin/$binary"
cat > "$root/usr/share/applications/$display_name.desktop" <<EOF
[Desktop Entry]
Categories=Development;
Comment=$summary
Exec=$binary %U
StartupWMClass=$identifier
Icon=$binary
Name=$display_name
Terminal=false
Type=Application
EOF
sizes_dir="$(dirname "$icon")/sizes"
for size in 32 128 256 512; do
  dir="$root/usr/share/icons/hicolor/${size}x${size}/apps"
  mkdir -p "$dir"
  cp "$sizes_dir/app_icon_$size.png" "$dir/$binary.png"
done
mkdir -p "$root/usr/share/icons/hicolor/256x256@2/apps"
cp "$sizes_dir/app_icon_512.png" "$root/usr/share/icons/hicolor/256x256@2/apps/$binary.png"

installed_kb=$(du -sk "$root/usr" | cut -f1)
mkdir -p "$root/DEBIAN"
cat > "$root/DEBIAN/control" <<EOF
Package: $package
Version: $version
Architecture: amd64
Installed-Size: $installed_kb
Maintainer: Ryko
Priority: optional
Depends: libgtk-3-0 | libgtk-3-0t64, libx11-6, libxi6, liblzma5
Description: $summary
 GodotHub manages Godot versions and projects.
EOF
deb="$slug-$version-linux-amd64.deb"
dpkg-deb --root-owner-group --build "$root" "$out_dir/$deb"
rm -rf "$root/DEBIAN"
echo "$out_dir/$deb"

rpmtop="$work/rpm"
mkdir -p "$rpmtop/SPECS" "$rpmtop/BUILDROOT" "$rpmtop/RPMS"
{
  echo "Name: $package"
  echo "Version: $version"
  echo "Release: 1"
  echo "Summary: $summary"
  echo "License: MIT"
  echo "BuildArch: x86_64"
  echo "AutoReqProv: no"
  echo "Requires: gtk3, libX11, libXi, xz-libs"
  echo
  echo "%description"
  echo "$summary"
  echo
  echo "%install"
  echo "cp -a $root/. %{buildroot}/"
  echo
  echo "%files"
  echo "/usr/lib/$binary"
  echo "/usr/bin/$binary"
  echo "\"/usr/share/applications/$display_name.desktop\""
  echo "/usr/share/icons/hicolor/*/apps/$binary.png"
} > "$rpmtop/SPECS/$package.spec"
rpmbuild --define "_topdir $rpmtop" --define "_build_id_links none" --define "__strip /bin/true" -bb "$rpmtop/SPECS/$package.spec"
rpm="$slug-$version-linux-x86_64.rpm"
mv "$rpmtop/RPMS/x86_64/$package-$version-1.x86_64.rpm" "$out_dir/$rpm"
echo "$out_dir/$rpm"
