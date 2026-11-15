#!/usr/bin/env bash
set -euo pipefail

bundle="${1:?usage: check_test_switches.sh <built app folder or .app bundle>}"
marker='GODOTHUB-TEST-SWITCH:'

snapshots="$(find "$bundle" -type f \( -name app.so -o -name libapp.so -o -path '*App.framework/App' -o -path '*App.framework/Versions/A/App' \) 2>/dev/null || true)"
if [ -z "$snapshots" ]; then
  echo "No compiled Dart code (app.so, libapp.so or App.framework/App) found in $bundle" >&2
  exit 1
fi

failed=0
while IFS= read -r snapshot; do
  found="$(grep -a -o "${marker}[A-Z_]*" "$snapshot" | sort -u || true)"
  if [ -n "$found" ]; then
    echo "$snapshot was built with test switches:" >&2
    echo "$found" | sed "s/^${marker}/  /" >&2
    failed=1
  else
    echo "ok: no test switches in $snapshot"
  fi
done <<EOF
$snapshots
EOF
exit "$failed"
