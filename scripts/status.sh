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

load_pkgbuild
release_tag=$(release_tag)

pkgfile=$(find_pkgfile_for "$PKGBASE")
mono_pkgfile=$(find_pkgfile_for "${PKGBASE}-mono")

printf 'pkgver=%s\n' "$pkgver"
printf 'pkgrel=%s\n' "$pkgrel"
printf 'release_tag=%s\n' "$release_tag"
printf 'source_artifact=%s\n' "$pkgfile"
printf 'source_mono_artifact=%s\n' "$mono_pkgfile"

if ls -1 "$DIST_DIR"/*.pkg.tar.zst >/dev/null 2>&1; then
  dist_file=$(find_dist_pkgfile_for "$PKGBASE")
  printf 'release_artifact=%s\n' "$dist_file"
  dist_mono_file=$(find_dist_pkgfile_for "${PKGBASE}-mono")
  printf 'release_mono_artifact=%s\n' "$dist_mono_file"
fi
