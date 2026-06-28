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
Usage: gdops update [--dry-run]
       gdops update [--dry-run] latest
       gdops update [--dry-run] <pkgver> <pkgrel>

Runs the Dockerized test-plus-stage update flow. With no version argument,
updates to the latest matching Arch godot/godot-mono package version.
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

if [[ $# -eq 0 ]]; then
  set -- latest
elif [[ "$1" == "latest" ]]; then
  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi
else
  if [[ $# -ne 2 ]]; then
    usage
    exit 1
  fi
  validate_bump_args "$1" "$2"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  "$SCRIPT_DIR/docker.sh" --dry-run ci "$@"
else
  "$SCRIPT_DIR/docker.sh" ci "$@"
fi
