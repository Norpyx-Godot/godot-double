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
Usage: gdops aur-keywords [--dry-run]

Applies the configured AUR package-base keywords using:
  ssh aur@aur.archlinux.org set-keywords <pkgbase> [...]

Keywords are AUR-side metadata. They are not a PKGBUILD/.SRCINFO field.
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

if ! declare -p AUR_KEYWORDS >/dev/null 2>&1; then
  die "AUR_KEYWORDS is not configured"
fi
if ! declare -p AUR_BIN_KEYWORDS >/dev/null 2>&1; then
  die "AUR_BIN_KEYWORDS is not configured"
fi

validate_keywords() {
  local keyword
  for keyword in "$@"; do
    [[ "$keyword" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || die "invalid AUR keyword: $keyword"
  done
}

set_keywords() {
  local package_base="$1"
  shift

  validate_keywords "$@"
  log "Setting AUR keywords for $package_base: $*"
  run_cmd ssh aur@aur.archlinux.org set-keywords "$package_base" "$@"
}

if [[ "$DRY_RUN" -eq 0 ]]; then
  require_cmd ssh
fi

set_keywords "$PKGBASE" "${AUR_KEYWORDS[@]}"
set_keywords "$PKGBASE_BIN" "${AUR_BIN_KEYWORDS[@]}"
