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
Usage: gdops test [--dry-run]

Runs lightweight automation tests and shell syntax checks.
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

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: would run shell syntax checks and tests"
  exit 0
fi

require_file "$ROOT_DIR/tests/run.sh"

bash -n "$ROOT_DIR/bin/gdops" "$ROOT_DIR"/scripts/*.sh "$ROOT_DIR"/tests/*.sh "$ROOT_DIR/docker/entrypoint.sh"
"$ROOT_DIR/tests/run.sh"

log "Test stage passed"
