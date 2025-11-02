#!/usr/bin/env bash
set -euo pipefail

# Constants
PKGBASE_SRC="godot-double"
PKGBASE_BIN="godot-double-bin"
PKGBASE_GH="godot-double-gh"
CARCH=x86_64

# Validate project structure
for dir in "$PKGBASE_SRC" "$PKGBASE_BIN" "$PKGBASE_GH"; do
	[[ -d "$dir" ]] || { echo "Missing directory: $dir"; exit 1; }
done

# Build godot-double
echo "==> Building $PKGBASE_SRC..."
cd "$PKGBASE_SRC"
#makepkg -f --noconfirm

# Copy the built package to us
PKGFILE=$(ls *.pkg.tar.zst | grep -v "mono" | tail -n1)
cp "$PKGFILE" "../$PKGBASE_GH/"
cd ..

# Source PKGBUILD from main package
echo "==> Reading metadata from $PKGBASE_SRC/PKGBUILD..."
source "$PKGBASE_SRC/PKGBUILD"
RELEASE_TAG="v${pkgver}-${pkgrel}"

# Compute SHA256
echo "==> Calculating SHA256..."
BIN_PKGFILE="$PKGBASE_GH/$PKGFILE"
BIN_SHA256=$(sha256sum "$BIN_PKGFILE" | awk '{ print $1 }')

# Extract GitHub repo URL from godot-double-gh
echo "==> Determining GitHub release URL..."
cd "$PKGBASE_GH"
GH_REMOTE=$(git remote get-url origin)

# Normalize the URL
if [[ "$GH_REMOTE" =~ ^git@github.com:(.*).git$ ]]; then
	GH_REPO="https://github.com/${BASH_REMATCH[1]}"
elif [[ "$GH_REMOTE" =~ ^https://github.com/(.*).git$ ]]; then
	GH_REPO="https://github.com/${BASH_REMATCH[1]}"
fi
cd ..

# Derive URL to the tarball in the GitHub release
TAR_NAME=$(basename "$BIN_PKGFILE")
TAR_URL="$GH_REPO/releases/download/$RELEASE_TAG/$TAR_NAME"

# Generate PKGBUILD for godot-double-bin
echo "==> Writing $PKGBASE_BIN/PKGBUILD..."
cat > "$PKGBASE_BIN/PKGBUILD" <<EOF
# Maintainer: Joseph Dalrymple <joseph.dalrymple@bluelogicteam.com>
# Contributor: Alexander F. Rødseth <xyproto@archlinux.org>
# Contributor: loqs
# Contributor: Jorge Araya Navarro <jorgejavieran@yahoo.com.mx>
# Contributor: Cristian Porras <porrascristian@gmail.com>
# Contributor: Matthew Bentley <matthew@mtbentley.us>
# Contributor: HurricanePootis <hurricanepootis@protonmail.com>
# Contributor: Toolybird <toolybird at tuta dot io>

pkgname=${pkgname}-bin
pkgver=${pkgver}
pkgrel=${pkgrel}
pkgdesc='${pkgdesc}'
arch=(${arch[@]})
url="${url}"
license=(${license[@]})
provides=("${pkgname}")
conflicts=("${pkgname}")
source=("${TAR_NAME}::${TAR_URL}")
noextract=("${TAR_NAME}")
sha256sums=('${BIN_SHA256}')

package() {
	bsdtar -xf "\${srcdir}/${TAR_NAME}" -C "\${pkgdir}" --strip-components=0 usr
}
EOF

# Generate .SRCINFO
echo "==> Generating .SRCINFO..."
cd "$PKGBASE_BIN"
makepkg --printsrcinfo > .SRCINFO
cd ..

# Success! :D
echo "✅ Hydration complete!"
echo "  - Built:        $PKGFILE"
echo "  - SHA256:       $BIN_SHA256"
echo "  - Copied to:    $PKGBASE_GH/, $PKGBASE_BIN/"
echo "  - Generated:    $PKGBASE_BIN/PKGBUILD"
echo "  - Generated:    $PKGBASE_BIN/.SRCINFO"
echo "  - Source URL:   $TAR_URL"

