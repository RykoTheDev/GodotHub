#!/usr/bin/env bash
# Runs the steps of the "checks" job in .github/workflows/flutter-ci.yml
# locally, so failures show up before a push. Keep the two in sync.
#
#   dev/tool/ci_local.sh            run here (Windows Git Bash, macOS, Linux)
#   dev/tool/ci_local.sh --linux    run inside WSL on a copy of the working
#                                   tree, like the Ubuntu runner. Needs Flutter,
#                                   Rust and Node installed inside WSL. Started
#                                   with WSL's bash (PowerShell "bash"), this is
#                                   what happens even without the flag.
#   dev/tool/ci_local.sh --fast     skip the Rust tests
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fast=0
linux=0
for arg in "$@"; do
  case "$arg" in
    --fast) fast=1 ;;
    --linux) linux=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# Linux runs never happen on the Windows checkout itself: Linux tools there
# fight the Windows .dart_tool, build and target folders, and git in WSL sees
# every CRLF file as changed. Instead the tree is copied into the WSL home.
# That covers --linux from Git Bash and any run started with WSL's bash (for
# example "bash" typed in PowerShell) on a /mnt/ path.
on_wsl_mount=0
[ "$(uname -s)" = "Linux" ] && case "$repo" in /mnt/*) on_wsl_mount=1 ;; esac
if { [ "$linux" = 1 ] && [ "$(uname -s)" != "Linux" ]; } || [ "$on_wsl_mount" = 1 ]; then
  if [ "$on_wsl_mount" = 1 ]; then
    linux_repo="$repo"
  else
    # Forward slashes (S:/...) survive the trip into WSL; backslashes don't.
    linux_repo="$(wsl wslpath -a "$(cygpath -m "$repo" 2>/dev/null || echo "$repo")" | tr -d '\r')"
  fi
  flags=""
  [ "$fast" = 1 ] && flags="--fast"
  # A login shell, so ~/.profile puts the Linux Flutter, Rust and Node first.
  script="
    set -e
    for tool in flutter cargo node rsync; do
      command -v \$tool >/dev/null || { echo \"Install \$tool inside WSL first.\" >&2; exit 1; }
    done
    case \"\$(command -v flutter)\" in /mnt/*) echo 'WSL is using the Windows Flutter; install the Linux one.' >&2; exit 1 ;; esac
    if ! command -v pkg-config >/dev/null || ! pkg-config --exists gtk+-3.0 x11 xi; then
      echo 'Missing the Linux libraries CI installs. Run in WSL:' >&2
      echo '  sudo apt-get update && sudo apt-get install -y clang pkg-config libgtk-3-dev libx11-dev libxi-dev' >&2
      exit 1
    fi
    # A fresh copy each run, so files deleted here are gone there too. Rust
    # build output lives outside it and is reused between runs.
    dest=\"\$HOME/.cache/godothub-ci\"
    rm -rf \"\$dest\" && mkdir -p \"\$dest\"
    cd '$linux_repo'
    git ls-files -co --exclude-standard -z | rsync -a --from0 --files-from=- ./ \"\$dest/\"
    cd \"\$dest\"
    export CARGO_TARGET_DIR=\"\$HOME/.cache/godothub-ci-target\"
    bash dev/tool/ci_local.sh $flags
  "
  if [ "$on_wsl_mount" = 1 ]; then
    exec bash -lc "$script"
  fi
  exec wsl -e bash -lc "$script"
fi

step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
failed=()
run() {
  local name="$1"; shift
  step "$name"
  if ! "$@"; then failed+=("$name"); fi
}

cd "$repo"
if [ "$fast" = 0 ]; then
  run "Rust tests for core and bridge" cargo test -p godothub_core -p godothub_bridge --locked
fi
run "Third-party Rust notices are up to date" node dev/tool/gen_rust_notices.mjs --check

cd "$repo/app"
run "Get Flutter packages" flutter pub get
step "Generate locale code"
dart run slang || failed+=("Generate locale code")
# Line endings alone don't count: on Windows the generators write LF into a
# CRLF checkout. Put such files back so the working tree stays clean.
if [ -d "$repo/.git" ] && [ -n "$(git status --porcelain -- lib/i18n)" ]; then
  if git diff --ignore-cr-at-eol --quiet -- lib/i18n; then
    git -c core.safecrlf=false checkout -- lib/i18n 2>/dev/null || true
  else
    git diff --ignore-cr-at-eol --stat -- lib/i18n
    echo "Warning: app/lib/i18n changed after running slang. Commit it, or CI will warn."
  fi
fi
run "i18n missing keys and values" dart run ../dev/tool/i18n/check_keys.dart --check-values
run "i18n duplicate keys" dart run ../dev/tool/i18n/duplicate_keys.dart
run "i18n unused keys" dart run ../dev/tool/i18n/unused_keys.dart
run "Analyze" flutter analyze
run "Widget tests" flutter test

echo
if [ "${#failed[@]}" -gt 0 ]; then
  printf '\033[31mFailed:\033[0m\n'
  printf '  - %s\n' "${failed[@]}"
  exit 1
fi
printf '\033[32mAll CI checks passed.\033[0m\n'
