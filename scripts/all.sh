#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Usage: gdops all [--push] [--dry-run] <pkgver> <pkgrel>

Runs the full release flow: bump, refresh, build, hydrate, release, commit.
USAGE
}

push_after=0
if [[ "${1:-}" == "--push" ]]; then
  push_after=1
  shift
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  export DRY_RUN=1
  shift
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

pkgver="$1"
pkgrel="$2"

"$SCRIPT_DIR/bump.sh" "$pkgver" "$pkgrel"
"$SCRIPT_DIR/refresh.sh"
"$SCRIPT_DIR/build.sh"
"$SCRIPT_DIR/hydrate-bin.sh"
"$SCRIPT_DIR/release.sh"
"$SCRIPT_DIR/commit.sh"

if [[ $push_after -eq 1 ]]; then
  "$SCRIPT_DIR/push.sh"
fi
