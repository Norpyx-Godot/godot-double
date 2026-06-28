#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

require_dirs
if [[ "$DRY_RUN" -eq 0 ]]; then
  require_cmd makepkg
fi

load_pkgbuild

existing_pkgfile_for() {
  local package_name="$1"
  local matches=()
  local pkgfile
  local saved_nullglob

  saved_nullglob="$(shopt -p nullglob || true)"
  shopt -s nullglob
  matches=("$SRC_DIR/${package_name}-${pkgver}-${pkgrel}-"*.pkg.tar.zst)
  eval "$saved_nullglob"

  for pkgfile in "${matches[@]}"; do
    [[ -s "$pkgfile" ]] || continue
    return 0
  done
  return 1
}

if [[ "${GDOPS_FORCE_BUILD:-0}" != "1" ]]; then
  if existing_pkgfile_for "$PKGBASE" >/dev/null &&
    existing_pkgfile_for "$PKGBASE-mono" >/dev/null; then
    log "Skipping build; package artifacts already exist for $pkgver-$pkgrel"
    log "Set GDOPS_FORCE_BUILD=1 to rebuild anyway"
    exit 0
  fi
fi

log "Building package in $SRC_DIR"
run_cmd_str "cd \"$SRC_DIR\" && makepkg $MAKEPKG_ARGS"
