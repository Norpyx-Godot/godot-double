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
  require_cmd sha256sum
  require_cmd makepkg
fi

load_pkgbuild

if [[ -z "$GH_REPO" ]]; then
  die "GH_REPO is not set. Update config.sh or config.local.sh."
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: skipping artifact lookup in $SRC_DIR"
  pkgfile="$SRC_DIR/${PKGBASE}-${pkgver}-${pkgrel}-DRY_RUN.pkg.tar.zst"
  mono_pkgfile="$SRC_DIR/${PKGBASE}-mono-${pkgver}-${pkgrel}-DRY_RUN.pkg.tar.zst"
else
  pkgfile=$(find_pkgfile_for "$PKGBASE")
  mono_pkgfile=$(find_pkgfile_for "${PKGBASE}-mono")
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: skipping artifact copy to $DIST_DIR"
  bin_pkgfile="$pkgfile"
  bin_mono_pkgfile="$mono_pkgfile"
else
  run_cmd mkdir -p "$DIST_DIR"
  run_cmd cp -f "$pkgfile" "$DIST_DIR/"
  run_cmd cp -f "$mono_pkgfile" "$DIST_DIR/"
  bin_pkgfile="$DIST_DIR/$(basename "$pkgfile")"
  bin_mono_pkgfile="$DIST_DIR/$(basename "$mono_pkgfile")"
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
  sha256="DRY_RUN"
  mono_sha256="DRY_RUN"
else
  sha256=$(sha256sum "$bin_pkgfile" | awk '{print $1}')
  mono_sha256=$(sha256sum "$bin_mono_pkgfile" | awk '{print $1}')
fi

base_pkgname="${pkgbase:-${pkgname[0]}}"
release_tag=$(release_tag)
tar_name=$(basename "$bin_pkgfile")
mono_tar_name=$(basename "$bin_mono_pkgfile")
tar_url="https://github.com/${GH_REPO}/releases/download/${release_tag}/${tar_name}"
mono_tar_url="https://github.com/${GH_REPO}/releases/download/${release_tag}/${mono_tar_name}"

format_array_values() {
  local item
  for item in "$@"; do
    printf "'%s' " "$item"
  done
}

arch_list="$(format_array_values "${arch[@]}")"
license_list="$(format_array_values "${license[@]}")"
depends_list="$(format_array_values "${depends[@]}")"
optdepends_list="$(format_array_values "${optdepends[@]}")"

log "Writing $BIN_DIR/PKGBUILD"
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: would write $BIN_DIR/PKGBUILD"
else
  cat > "$BIN_DIR/PKGBUILD" <<EOF
# Maintainer: Joseph Dalrymple <joseph.dalrymple@bluelogicteam.com>
# Contributor: Alexander F. Rødseth <xyproto@archlinux.org>
# Contributor: loqs
# Contributor: Jorge Araya Navarro <jorgejavieran@yahoo.com.mx>
# Contributor: Cristian Porras <porrascristian@gmail.com>
# Contributor: Matthew Bentley <matthew@mtbentley.us>
# Contributor: HurricanePootis <hurricanepootis@protonmail.com>
# Contributor: Toolybird <toolybird at tuta dot io>

pkgbase=${base_pkgname}-bin
pkgname=(${base_pkgname}-bin ${base_pkgname}-mono-bin)
pkgver=${pkgver}
pkgrel=${pkgrel}
pkgdesc='${pkgdesc}'
arch=(${arch_list})
url="${url}"
license=(${license_list})
depends=(${depends_list})
optdepends=(${optdepends_list})
source=("${tar_name}::${tar_url}"
        "${mono_tar_name}::${mono_tar_url}")
noextract=("${tar_name}" "${mono_tar_name}")
sha256sums=('${sha256}'
            '${mono_sha256}')

package_${base_pkgname}-bin() {
	provides=("${base_pkgname}")
	conflicts=("${base_pkgname}")
	bsdtar -xf "\${srcdir}/${tar_name}" -C "\${pkgdir}" --strip-components=0 usr
}

package_${base_pkgname}-mono-bin() {
	provides=("${base_pkgname}-mono")
	conflicts=("${base_pkgname}-mono")
	depends+=(dotnet-sdk-8.0)
	bsdtar -xf "\${srcdir}/${mono_tar_name}" -C "\${pkgdir}" --strip-components=0 usr
}
EOF
fi

log "Regenerating $BIN_DIR/.SRCINFO"
run_cmd_str "cd \"$BIN_DIR\" && makepkg --printsrcinfo > .SRCINFO"

log "Hydration complete"
log "  - Release tag: $release_tag"
log "  - Artifact: $bin_pkgfile"
log "  - SHA256: $sha256"
log "  - Source URL: $tar_url"
log "  - Mono artifact: $bin_mono_pkgfile"
log "  - Mono SHA256: $mono_sha256"
log "  - Mono source URL: $mono_tar_url"
