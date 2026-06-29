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
Usage: gdops release [--dry-run]

Creates or repairs the GitHub release for the current package version, uploading
both godot-double and godot-double-mono source package artifacts from dist/.
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
  mono_asset="$DIST_DIR/${PKGBASE}-mono-${pkgver}-${pkgrel}-DRY_RUN.pkg.tar.zst"
else
  asset=$(find_dist_pkgfile_for "$PKGBASE")
  mono_asset=$(find_dist_pkgfile_for "${PKGBASE}-mono")
fi

log "Publishing GitHub release $release_tag for $GH_REPO"
log "  - Asset: $asset"
log "  - Mono asset: $mono_asset"

if [[ "$DRY_RUN" -eq 0 ]] && gh release view "$release_tag" --repo "$GH_REPO" >/dev/null 2>&1; then
  log "Release already exists; uploading artifacts"
  run_cmd gh release upload "$release_tag" "$asset" "$mono_asset" \
    --repo "$GH_REPO" \
    --clobber
else
  run_cmd gh release create "$release_tag" "$asset" "$mono_asset" \
    --repo "$GH_REPO" \
    --title "$release_tag" \
    --notes ""
fi
