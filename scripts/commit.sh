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

load_pkgbuild
release_tag=$(release_tag)

commit_repo() {
  local repo_dir="$1"

  log "Committing updates in $repo_dir"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    (
      cd "$repo_dir"
      if [[ -z "$(git status --porcelain)" ]]; then
        log "No changes to commit in $repo_dir"
      else
        log "Dry run: would commit PKGBUILD/.SRCINFO with message $release_tag"
      fi
    )
    return 0
  fi

  (
    cd "$repo_dir"
    git add PKGBUILD .SRCINFO
    if git diff --cached --quiet; then
      log "No changes to commit in $repo_dir"
      return 0
    fi
    git commit -m "$release_tag"
  )
}

commit_repo "$SRC_DIR"
commit_repo "$BIN_DIR"
