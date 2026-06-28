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
Usage: gdops stage [--dry-run] <pkgver> <pkgrel>
       gdops stage [--dry-run] latest

Stages an update without publishing: preflight, bump, source-check, build,
artifact-check, and hydrate-check.
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

read -r pkgver_new pkgrel_new < <(resolve_bump_args "$@")
if [[ "${1:-}" == "latest" ]]; then
  shift 1
else
  shift 2
fi

if [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

stage_args=()
if [[ "$DRY_RUN" -eq 1 ]]; then
  stage_args+=(--dry-run)
fi

export GDOPS_EXPECTED_PKGVER="$pkgver_new"
export GDOPS_EXPECTED_PKGREL="$pkgrel_new"

log "Starting staging for $pkgver_new-$pkgrel_new"
"$SCRIPT_DIR/preflight.sh" "${stage_args[@]}" "$pkgver_new" "$pkgrel_new"
"$SCRIPT_DIR/bump.sh" "${stage_args[@]}" "$pkgver_new" "$pkgrel_new"
"$SCRIPT_DIR/bump-check.sh" "${stage_args[@]}" "$pkgver_new" "$pkgrel_new"
"$SCRIPT_DIR/source-check.sh" "${stage_args[@]}"
"$SCRIPT_DIR/build.sh" "${stage_args[@]}"
"$SCRIPT_DIR/artifact-check.sh" "${stage_args[@]}"
"$SCRIPT_DIR/hydrate-check.sh" "${stage_args[@]}"

log "Staging complete for $pkgver_new-$pkgrel_new"
