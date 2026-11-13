#!/usr/bin/env bash
set -euo pipefail

channel="$1"
identifier="$2"
display_name="$3"

app="$(cd "$(dirname "$0")/../.." && pwd)"
info="$app/macos/Runner/Configs/AppInfo.xcconfig"
sed -i.bak \
  -e "s|^PRODUCT_NAME = .*|PRODUCT_NAME = $display_name|" \
  -e "s|^PRODUCT_BUNDLE_IDENTIFIER = .*|PRODUCT_BUNDLE_IDENTIFIER = $identifier|" \
  "$info"
rm -f "$info.bak"
grep -q "^PRODUCT_NAME = $display_name\$" "$info"
grep -q "^PRODUCT_BUNDLE_IDENTIFIER = $identifier\$" "$info"

if [ "$channel" = stable ]; then
  icons="$app/macos/Runner/Assets.xcassets/AppIcon.appiconset"
  for size in 16 32 64 128 256 512 1024; do
    cp "$app/packaging/icons/stable/sizes/app_icon_$size.png" "$icons/app_icon_$size.png"
  done
fi
echo "macOS project set to $display_name ($identifier)"
