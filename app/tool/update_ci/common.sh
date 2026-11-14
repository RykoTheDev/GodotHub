#!/usr/bin/env bash

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
lab="${UPDATE_LAB:-$root/lab}"
port="${UPDATE_LAB_PORT:-47821}"
results="$lab/results"
report="${TMPDIR:-/tmp}"
report="${report%/}/godothub-updater-lab.txt"
failures=0
mkdir -p "$results" "$lab/serve"
: > "$results/checks.txt"

note() { echo "$*" | tee -a "$results/checks.txt"; }
check() {
  local what="$1"; shift
  if "$@"; then note "ok   $what"; else note "FAIL $what"; failures=$((failures + 1)); fi
}

serve() {
  cp "$lab/manifests/$1.json" "$lab/serve/latest-v2.json"
  ln -sfn "$lab/dist/1.9.1" "$lab/serve/1.9.1"
  if [ -z "${server_pid:-}" ]; then
    python3 -m http.server "$port" --bind 127.0.0.1 --directory "$lab/serve" > "$results/server.log" 2>&1 &
    server_pid=$!
    sleep 2
  fi
}

started() {
  local version="$1" seconds="${2:-240}"
  for _ in $(seq 1 $((seconds / 2))); do
    grep -q "^started $version" "$report" 2>/dev/null && return 0
    sleep 2
  done
  return 1
}

save_report() {
  cp "$report" "$results/report-$1.txt" 2>/dev/null || true
  note "     report: $(tr '\n' '|' < "$report" 2>/dev/null | cut -c1-400)"
}

finish() {
  [ -n "${server_pid:-}" ] && kill "$server_pid" 2>/dev/null || true
  note ""
  note "$failures failure(s)"
  echo "$failures" > "$results/done.txt"
  exit "$failures"
}
