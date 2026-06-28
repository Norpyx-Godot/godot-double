#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Usage: gdops validate [--dry-run] <pkgver> <pkgrel>
       gdops validate [--dry-run] latest

Compatibility alias for gdops stage.
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

"$SCRIPT_DIR/stage.sh" "$@"
