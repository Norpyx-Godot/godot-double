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
Usage: gdops sync-arch-pkgbuild [--dry-run]

Fetches the official Arch godot package source and transforms its split
PKGBUILD into godot-double/godot-double-mono.
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

write_transformed_pkgbuild() {
  local source_pkgbuild="$1"
  local target_pkgbuild="$2"
  local tmp_pkgbuild

  tmp_pkgbuild="$(mktemp)"
  trap 'rm -f "$tmp_pkgbuild"' RETURN

  awk '
    /^pkgbase=godot$/ {
      print "pkgbase=godot-double"
      next
    }
    /^pkgname=\(godot godot-mono\)$/ {
      print "pkgname=(godot-double godot-double-mono)"
      next
    }
    /^pkgdesc=/ {
      print "pkgdesc='\''Advanced cross-platform 2D and 3D game engine (double-precision build)'\''"
      next
    }
    /^source=\("git\+https:\/\/github.com\/godotengine\/godot#tag=\$pkgver-stable"\)$/ {
      print "source=(\"godot::git+https://github.com/godotengine/godot#tag=$pkgver-stable\")"
      next
    }
    /^prepare\(\)/ {
      exit
    }
    {
      print
    }
  ' "$source_pkgbuild" > "$tmp_pkgbuild"

  cat >> "$tmp_pkgbuild" <<'PKGBUILD_PREPARE'

prepare() {
  cd godot

  # Patch for miniupnpc
  sed -i 's/addr, 16/addr, 16, nullptr, 0/g' modules/upnp/upnp.cpp

  cd misc/dist/linux

  cp -f org.godotengine.Godot.desktop org.godotengine.Godot-Double.desktop
  setconf org.godotengine.Godot-Double.desktop Exec godot-double
  setconf org.godotengine.Godot-Double.desktop Icon godot-double.svg
  setconf org.godotengine.Godot-Double.desktop Name 'Godot Engine (Double Precision)'

  sed -i 's,xmlns="https://specifications.freedesktop.org/shared-mime-info-spec",xmlns="http://www.freedesktop.org/standards/shared-mime-info",g' \
    org.godotengine.Godot.xml
  cp -f org.godotengine.Godot.xml org.godotengine.Godot-Double.xml

  cp -f org.godotengine.Godot.desktop org.godotengine.Godot-Double-mono.desktop
  setconf org.godotengine.Godot-Double-mono.desktop Exec godot-double-mono
  setconf org.godotengine.Godot-Double-mono.desktop Icon godot-double-mono.svg
  setconf org.godotengine.Godot-Double-mono.desktop Name 'Godot Engine Mono (Double Precision)'

  cp -f org.godotengine.Godot.xml org.godotengine.Godot-Double-mono.xml
}

PKGBUILD_PREPARE

  awk '
    /^case \$CARCH/ {
      emit = 1
    }
    /^package_godot\(\)/ {
      emit = 0
    }
    emit {
      print
    }
  ' "$source_pkgbuild" |
    sed \
      -e 's/cd \$pkgname/cd godot/g' \
      -e 's/bin\/godot\.linuxbsd\.editor\.\$_CARCH\.mono/bin\/godot.linuxbsd.editor.double.$_CARCH.mono/g' \
      -e 's/--godot-platform=linuxbsd$/--godot-platform=linuxbsd --precision=double/' \
      -e '/pulseaudio=yes/a\    precision=double' \
    >> "$tmp_pkgbuild"

  cat >> "$tmp_pkgbuild" <<'PKGBUILD_PACKAGES'
package_godot-double() {
  cd godot

  install -Dm755 bin/godot.linuxbsd.editor.double.$_CARCH "$pkgdir/usr/bin/godot-double"

  install -Dm644 misc/logo/icon.svg "$pkgdir/usr/share/pixmaps/$pkgname.svg"
  install -Dm644 misc/dist/linux/org.godotengine.Godot-Double.desktop "$pkgdir/usr/share/applications/org.godotengine.Godot-Double.desktop"
  install -Dm644 misc/dist/linux/org.godotengine.Godot-Double.xml "$pkgdir/usr/share/mime/packages/org.godotengine.Godot-Double.xml"

  install -Dm644 misc/dist/linux/godot.6 "$pkgdir/usr/share/man/man6/$pkgname.6"
  install -Dm644 LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

package_godot-double-mono() {
  depends+=(dotnet-sdk-8.0)

  cd godot

  install -Dm755 bin/godot.linuxbsd.editor.double.$_CARCH.mono "$pkgdir/usr/lib/$pkgname/godot.linuxbsd.editor.double.$_CARCH.mono"

  cp -a bin/GodotSharp "$pkgdir/usr/lib/$pkgname/"
  install -d "$pkgdir/usr/bin"
  ln -s /usr/lib/$pkgname/godot.linuxbsd.editor.double.$_CARCH.mono "$pkgdir/usr/bin/$pkgname"

  install -Dm644 misc/logo/icon.svg "$pkgdir/usr/share/pixmaps/$pkgname.svg"
  install -Dm644 misc/dist/linux/org.godotengine.Godot-Double-mono.desktop "$pkgdir/usr/share/applications/org.godotengine.Godot-Double-mono.desktop"
  install -Dm644 misc/dist/linux/org.godotengine.Godot-Double-mono.xml "$pkgdir/usr/share/mime/packages/org.godotengine.Godot-Double-mono.xml"

  install -Dm644 misc/dist/linux/godot.6 "$pkgdir/usr/share/man/man6/$pkgname.6"
  install -Dm644 LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
PKGBUILD_PACKAGES

  run_cmd cp "$tmp_pkgbuild" "$target_pkgbuild"
}

require_dirs

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: would clone official Arch godot package source into $ARCH_SRC_DIR"
  log "Dry run: would transform official PKGBUILD into $SRC_DIR/PKGBUILD"
  exit 0
fi

require_cmd pkgctl
require_cmd awk
require_cmd sed

run_cmd rm -rf "$ARCH_SRC_DIR/godot"
run_cmd mkdir -p "$ARCH_SRC_DIR"
(
  cd "$ARCH_SRC_DIR"
  run_cmd pkgctl repo clone --protocol=https godot
)

source_pkgbuild="$ARCH_SRC_DIR/godot/PKGBUILD"
require_file "$source_pkgbuild"
write_transformed_pkgbuild "$source_pkgbuild" "$SRC_DIR/PKGBUILD"

log "Synced $SRC_DIR/PKGBUILD from official Arch godot package source"
