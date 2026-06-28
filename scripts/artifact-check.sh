#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

usage() {
  cat <<'USAGE'
Usage: gdops artifact-check [--dry-run]

Checks that the source package build produced the expected package artifact.
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

if [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

require_dirs
load_pkgbuild

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: would verify $SRC_DIR/${PKGBASE}-${pkgver}-${pkgrel}-*.pkg.tar.zst"
  exit 0
fi

pkgfile="$(find_pkgfile)"
[[ -s "$pkgfile" ]] || die "package artifact is empty: $pkgfile"

log "Artifact check passed: $pkgfile"
