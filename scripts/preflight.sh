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
Usage: gdops preflight [--dry-run] [<pkgver> <pkgrel>]

Checks required package repositories, metadata files, config, and local tools.
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

if [[ $# -eq 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

if [[ $# -eq 2 ]]; then
  validate_bump_args "$1" "$2"
fi

require_pkg_metadata

if [[ -z "$GH_REPO" ]]; then
  die "GH_REPO is not set. Update config.sh or config.local.sh."
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  require_cmd git
  require_cmd makepkg
  require_cmd updpkgsums
  require_cmd sha256sum
fi

log "Preflight passed"
