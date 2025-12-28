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

log "Building package in $SRC_DIR"
run_cmd_str "cd \"$SRC_DIR\" && makepkg $MAKEPKG_ARGS"
