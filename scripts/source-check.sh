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
Usage: gdops source-check [--dry-run]

Refreshes source checksums and verifies godot-double/.SRCINFO is in sync.
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

stage_args=()
if [[ "$DRY_RUN" -eq 1 ]]; then
  stage_args+=(--dry-run)
fi

"$SCRIPT_DIR/pull.sh" "${stage_args[@]}"
"$SCRIPT_DIR/metadata-check.sh" "${stage_args[@]}" source

log "Source check passed"
