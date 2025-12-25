#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

require_dirs

load_pkgbuild
release_tag=$(release_tag)

pkgfile=$(find_pkgfile)

printf 'pkgver=%s\n' "$pkgver"
printf 'pkgrel=%s\n' "$pkgrel"
printf 'release_tag=%s\n' "$release_tag"
printf 'source_artifact=%s\n' "$pkgfile"

if ls -1 "$DIST_DIR"/*.pkg.tar.zst >/dev/null 2>&1; then
  dist_file=$(find_dist_pkgfile)
  printf 'release_artifact=%s\n' "$dist_file"
fi
