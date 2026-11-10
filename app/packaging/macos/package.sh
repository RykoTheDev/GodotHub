#!/usr/bin/env bash
set -euo pipefail

app_path="$1"
version="$2"
out_dir="$3"
identifier="$4"
display_name="$5"

bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")
bundle_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")
if [ "$bundle_id" != "$identifier" ]; then
  echo "bundle id $bundle_id does not match the channel identifier $identifier" >&2
  exit 1
fi
if [ "$bundle_version" != "$version" ]; then
  echo "bundle version $bundle_version does not match $version" >&2
  exit 1
fi
if [ "$(basename "$app_path")" != "$display_name.app" ]; then
  echo "app bundle is $(basename "$app_path"), expected $display_name.app" >&2
  exit 1
fi

archs=$(lipo -archs "$app_path/Contents/MacOS/$display_name")
case "$archs" in
  *arm64*x86_64*|*x86_64*arm64*) ;;
  *) echo "expected a universal binary, got: $archs" >&2; exit 1 ;;
esac

slug="${display_name// /-}"
mkdir -p "$out_dir"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
ditto "$app_path" "$stage/$display_name.app"
ln -s /Applications "$stage/Applications"

dmg="$out_dir/$slug-$version-darwin-universal.dmg"
tarball="$out_dir/$slug-$version-darwin-universal.app.tar.gz"
rm -f "$dmg" "$tarball"
hdiutil create -volname "$display_name" -srcfolder "$stage" -ov -format UDZO "$dmg"
tar -C "$stage" -czf "$tarball" "$display_name.app"

echo "$dmg"
echo "$tarball"
