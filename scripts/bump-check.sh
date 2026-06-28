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
Usage: gdops bump-check [--dry-run] <pkgver> <pkgrel>

Checks that godot-double/PKGBUILD contains the expected bump version.
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

expected_pkgver="$1"
expected_pkgrel="$2"

validate_bump_args "$expected_pkgver" "$expected_pkgrel"
require_dirs
require_file "$SRC_DIR/PKGBUILD"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: would verify PKGBUILD bump to $expected_pkgver-$expected_pkgrel"
  exit 0
fi

load_pkgbuild

if [[ "$pkgver" != "$expected_pkgver" ]]; then
  die "PKGBUILD pkgver is $pkgver, expected $expected_pkgver"
fi

if [[ "$pkgrel" != "$expected_pkgrel" ]]; then
  die "PKGBUILD pkgrel is $pkgrel, expected $expected_pkgrel"
fi

log "Bump check passed for $pkgver-$pkgrel"
