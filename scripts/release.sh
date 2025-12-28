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
  require_cmd gh
fi

load_pkgbuild

if [[ -z "$GH_REPO" ]]; then
  die "GH_REPO is not set. Update config.sh or config.local.sh."
fi

release_tag=$(release_tag)
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: skipping release artifact lookup in $DIST_DIR"
  asset="$DIST_DIR/${PKGBASE}-${pkgver}-${pkgrel}-DRY_RUN.pkg.tar.zst"
else
  asset=$(find_dist_pkgfile)
fi

log "Creating GitHub release $release_tag for $GH_REPO"

run_cmd gh release create "$release_tag" "$asset" \
  --repo "$GH_REPO" \
  --title "$release_tag" \
  --notes ""
