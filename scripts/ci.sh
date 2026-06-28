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
Usage: gdops ci [--dry-run] <pkgver> <pkgrel>

Runs tests and the bump validation pipeline as one CI pass/fail gate.
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

if [[ "$DRY_RUN" -eq 1 ]]; then
  "$SCRIPT_DIR/test.sh" "${stage_args[@]}"
else
  "$ROOT_DIR/tests/coverage.sh"
fi
"$SCRIPT_DIR/stage.sh" "${stage_args[@]}" "$pkgver_new" "$pkgrel_new"

log "CI gate passed for $pkgver_new-$pkgrel_new"
