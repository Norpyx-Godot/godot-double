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
require_cmd git

push_repo() {
  local repo_dir="$1"

  log "Pushing $repo_dir to $AUR_REMOTE"
  (
    cd "$repo_dir"
    run_cmd git push "$AUR_REMOTE"
  )
}

push_repo "$SRC_DIR"
push_repo "$BIN_DIR"
