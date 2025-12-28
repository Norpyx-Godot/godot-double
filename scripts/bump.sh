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
Usage: gdops bump <pkgver> <pkgrel>

Updates pkgver/pkgrel in godot-double/PKGBUILD.
USAGE
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

require_dirs

pkgver_new="$1"
pkgrel_new="$2"

pkgbuild="$SRC_DIR/PKGBUILD"

if ! grep -q '^pkgver=' "$pkgbuild"; then
  die "pkgver not found in $pkgbuild"
fi
if ! grep -q '^pkgrel=' "$pkgbuild"; then
  die "pkgrel not found in $pkgbuild"
fi

log "Updating pkgver to $pkgver_new"
run_cmd sed -i "s/^pkgver=.*/pkgver=${pkgver_new}/" "$pkgbuild"
log "Updating pkgrel to $pkgrel_new"
run_cmd sed -i "s/^pkgrel=.*/pkgrel=${pkgrel_new}/" "$pkgbuild"
