#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

require_dirs
require_cmd sha256sum
require_cmd makepkg

load_pkgbuild

if [[ -z "$GH_REPO" ]]; then
  die "GH_REPO is not set. Update config.sh or config.local.sh."
fi

pkgfile=$(find_pkgfile)
mkdir -p "$DIST_DIR"
cp -f "$pkgfile" "$DIST_DIR/"

bin_pkgfile="$DIST_DIR/$(basename "$pkgfile")"
sha256=$(sha256sum "$bin_pkgfile" | awk '{print $1}')

base_pkgname="${pkgbase:-${pkgname[0]}}"
release_tag=$(release_tag)
tar_name=$(basename "$bin_pkgfile")
tar_url="https://github.com/${GH_REPO}/releases/download/${release_tag}/${tar_name}"

arch_list="${arch[*]}"
license_list="${license[*]}"

log "Writing $BIN_DIR/PKGBUILD"
cat > "$BIN_DIR/PKGBUILD" <<EOF
# Maintainer: Joseph Dalrymple <joseph.dalrymple@bluelogicteam.com>
# Contributor: Alexander F. Rødseth <xyproto@archlinux.org>
# Contributor: loqs
# Contributor: Jorge Araya Navarro <jorgejavieran@yahoo.com.mx>
# Contributor: Cristian Porras <porrascristian@gmail.com>
# Contributor: Matthew Bentley <matthew@mtbentley.us>
# Contributor: HurricanePootis <hurricanepootis@protonmail.com>
# Contributor: Toolybird <toolybird at tuta dot io>

pkgname=${base_pkgname}-bin
pkgver=${pkgver}
pkgrel=${pkgrel}
pkgdesc='${pkgdesc}'
arch=(${arch_list})
url="${url}"
license=(${license_list})
provides=("${base_pkgname}")
conflicts=("${base_pkgname}")
source=("${tar_name}::${tar_url}")
noextract=("${tar_name}")
sha256sums=('${sha256}')

package() {
	bsdtar -xf "\${srcdir}/${tar_name}" -C "\${pkgdir}" --strip-components=0 usr
}
EOF

log "Regenerating $BIN_DIR/.SRCINFO"
(
  cd "$BIN_DIR"
  makepkg --printsrcinfo > .SRCINFO
)

log "Hydration complete"
log "  - Release tag: $release_tag"
log "  - Artifact: $bin_pkgfile"
log "  - SHA256: $sha256"
log "  - Source URL: $tar_url"
