#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

require_dirs
require_cmd gh

load_pkgbuild

if [[ -z "$GH_REPO" ]]; then
  die "GH_REPO is not set. Update config.sh or config.local.sh."
fi

release_tag=$(release_tag)
asset=$(find_dist_pkgfile)

log "Creating GitHub release $release_tag for $GH_REPO"

gh release create "$release_tag" "$asset" \
  --repo "$GH_REPO" \
  --title "$release_tag" \
  --notes ""
