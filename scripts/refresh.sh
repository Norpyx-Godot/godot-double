#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

require_dirs
require_cmd updpkgsums
require_cmd makepkg

log "Refreshing checksums in $SRC_DIR"
(
  cd "$SRC_DIR"
  updpkgsums
  makepkg --printsrcinfo > .SRCINFO
)
