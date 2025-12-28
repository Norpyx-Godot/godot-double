#!/usr/bin/env bash
set -euo pipefail

# Constants
PKGBASE_SRC="godot-double"
PKGBASE_BIN="godot-double-bin"
PKGBASE_GH="godot-double-gh"

# Validate project structure
for dir in "$PKGBASE_SRC" "$PKGBASE_BIN" "$PKGBASE_GH"; do
	[[ -d "$dir" ]] || { echo "Missing directory: $dir"; exit 1; }
	pushd "$dir" > /dev/null
	git clean -dxf
	popd > /dev/null
done

# Copy the built package to us
cd "$PKGBASE_SRC"
PKGFILE=$(ls *.pkg.tar.zst | grep -v "mono" | tail -n1)
cd ..

BIN_PKGFILE="$PKGBASE_SRC/$PKGFILE"
TAR_NAME=$(basename "$BIN_PKGFILE")
cp $BIN_PKGFILE $PKGBASE_GH

# Source PKGBUILD from main package
echo "==> Reading metadata from $PKGBASE_SRC/PKGBUILD..."
source "$PKGBASE_SRC/PKGBUILD"
RELEASE_TAG="v${pkgver}-${pkgrel}"

# Create GitHub Release
echo "==> Creating GitHub release: $RELEASE_TAG"
cd "$PKGBASE_GH"
gh release create "$RELEASE_TAG" "$TAR_NAME" \
  --title "$RELEASE_TAG" \
  --notes ""
cd ..

# Commit godot-double-bin
echo "==> Committing and pushing godot-double-bin/..."
cd "$PKGBASE_BIN"

git add PKGBUILD .SRCINFO
git commit -m "$RELEASE_TAG"
#git push

cd ..

echo "✅ Created release godot-double-bin for $RELEASE_TAG"

