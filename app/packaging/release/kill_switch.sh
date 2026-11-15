#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Stops or restarts the update rollout by swapping the update feed on a release.

  kill_switch.sh status
      Shows which release is latest and which version its update feed offers.
  kill_switch.sh pause <bad-tag> <good-tag> [--dry-run]
      Saves the feed of <bad-tag>, then uploads the feed of <good-tag> in its place.
      Nobody is offered <bad-tag> after this; nothing is downgraded.
  kill_switch.sh resume <bad-tag> [--dry-run]
      Puts the saved feed of <bad-tag> back.

Environment:
  REPO            owner/name on GitHub (default: the repository of the current folder)
  MANIFEST        feed file name (default: latest-v2.json)
  BACKUP_DIR      where saved feeds go (default: ./kill-switch-backups)
  LOCAL_RELEASES  rehearsal only: a folder with one subfolder per tag instead of GitHub
  LOCAL_URL       rehearsal only: the URL that serves the latest release's files
EOF
}

manifest="${MANIFEST:-latest-v2.json}"
backup_dir="${BACKUP_DIR:-$PWD/kill-switch-backups}"
local_releases="${LOCAL_RELEASES:-}"
dry_run=false
args=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    -h | --help) usage; exit 0 ;;
    *) args+=("$arg") ;;
  esac
done
set -- "${args[@]+"${args[@]}"}"
command="${1:-}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

repo() {
  if [ -z "${REPO:-}" ]; then REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"; fi
  printf '%s' "$REPO"
}

version_of() {
  node -e 'const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); if (!m.version || !m.platforms) process.exit(2); console.log(String(m.version).replace(/^v/, ""))' "$1"
}

older() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" = "$1" ]
}

fetch() {
  local tag="$1" out="$2"
  if [ -n "$local_releases" ]; then
    cp "$local_releases/$tag/$manifest" "$out"
  else
    gh release download "$tag" --repo "$(repo)" --pattern "$manifest" --output "$out" --clobber
  fi
}

publish() {
  local tag="$1" file="$2"
  if $dry_run; then
    echo "dry run: would upload $(version_of "$file") as $manifest on $tag"
    return
  fi
  if [ -n "$local_releases" ]; then
    cp "$file" "$local_releases/$tag/$manifest"
  else
    mkdir -p "$work/upload"
    cp "$file" "$work/upload/$manifest"
    gh release upload "$tag" "$work/upload/$manifest" --repo "$(repo)" --clobber
  fi
}

latest_url() {
  if [ -n "$local_releases" ]; then
    printf '%s/%s' "${LOCAL_URL:?LOCAL_URL is required with LOCAL_RELEASES}" "$manifest"
  else
    printf 'https://github.com/%s/releases/latest/download/%s' "$(repo)" "$manifest"
  fi
}

live_version() {
  curl -fsSL -H 'Cache-Control: no-cache' "$(latest_url)?t=$(date +%s)" -o "$work/live.json" && version_of "$work/live.json"
}

latest_tag() {
  if [ -n "$local_releases" ]; then
    cat "$local_releases/latest" 2>/dev/null || echo unknown
  else
    gh release view --repo "$(repo)" --json tagName -q .tagName
  fi
}

wait_for_live() {
  local want="$1" got=""
  for _ in $(seq 1 12); do
    got="$(live_version || true)"
    if [ "$got" = "$want" ]; then
      echo "live feed now offers $got ($(latest_url))"
      return 0
    fi
    sleep 5
  done
  echo "the live feed still offers ${got:-nothing} instead of $want; check $(latest_url) by hand" >&2
  return 1
}

case "$command" in
  status)
    echo "latest release: $(latest_tag)"
    echo "live feed offers: $(live_version || echo 'nothing (download failed)')"
    ;;
  pause)
    bad="${2:?usage: pause <bad-tag> <good-tag>}"
    good="${3:?usage: pause <bad-tag> <good-tag>}"
    [ "$(latest_tag)" = "$bad" ] || echo "warning: $bad is not the latest release ($(latest_tag)), so users never read its feed" >&2
    mkdir -p "$backup_dir"
    backup="$backup_dir/$bad-$manifest"
    fetch "$bad" "$work/current.json"
    fetch "$good" "$work/good.json"
    current_version="$(version_of "$work/current.json")"
    good_version="$(version_of "$work/good.json")"
    bad_version="${bad#v}"
    if [ "$current_version" = "$good_version" ]; then
      echo "$bad already offers $good_version; the rollout is paused"
      exit 0
    fi
    [ "$current_version" = "$bad_version" ] || { echo "$bad offers $current_version, not $bad_version; refusing to guess" >&2; exit 1; }
    older "$good_version" "$bad_version" || { echo "$good offers $good_version, which is not older than $bad_version" >&2; exit 1; }
    if [ -f "$backup" ] && ! cmp -s "$backup" "$work/current.json"; then
      echo "$backup already exists and differs from the live feed; move it away first" >&2
      exit 1
    fi
    $dry_run || cp "$work/current.json" "$backup"
    echo "saved the $bad_version feed to $backup"
    publish "$bad" "$work/good.json"
    $dry_run || wait_for_live "$good_version"
    ;;
  resume)
    bad="${2:?usage: resume <bad-tag>}"
    backup="$backup_dir/$bad-$manifest"
    [ -f "$backup" ] || { echo "no saved feed at $backup" >&2; exit 1; }
    want="$(version_of "$backup")"
    publish "$bad" "$backup"
    $dry_run || wait_for_live "$want"
    ;;
  *)
    usage
    [ -z "$command" ] || exit 64
    ;;
esac
