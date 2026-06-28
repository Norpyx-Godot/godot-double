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
Usage: gdops hydrate-check [--dry-run]

Generates godot-double-bin metadata from the built artifact and verifies it.
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

"$SCRIPT_DIR/hydrate-bin.sh" "${stage_args[@]}"
"$SCRIPT_DIR/metadata-check.sh" "${stage_args[@]}" bin

log "Hydrate check passed"
