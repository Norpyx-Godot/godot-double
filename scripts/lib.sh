#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/config.sh"
LOCAL_CONFIG_FILE="$ROOT_DIR/config.local.sh"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi
if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$LOCAL_CONFIG_FILE"
fi

PKGBASE="${PKGBASE:-godot-double}"
PKGBASE_BIN="${PKGBASE_BIN:-godot-double-bin}"
SRC_DIR="${SRC_DIR:-$ROOT_DIR/$PKGBASE}"
BIN_DIR="${BIN_DIR:-$ROOT_DIR/$PKGBASE_BIN}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
GH_REPO="${GH_REPO:-}"
RELEASE_PREFIX="${RELEASE_PREFIX:-v}"
AUR_REMOTE="${AUR_REMOTE:-origin}"
MAKEPKG_ARGS="${MAKEPKG_ARGS:--si}"

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

require_dirs() {
  [[ -d "$SRC_DIR" ]] || die "missing submodule: $SRC_DIR"
  [[ -d "$BIN_DIR" ]] || die "missing submodule: $BIN_DIR"
}

load_pkgbuild() {
  local pkgbuild="$SRC_DIR/PKGBUILD"
  [[ -f "$pkgbuild" ]] || die "missing PKGBUILD: $pkgbuild"

  local saved_carch="${CARCH-}"
  CARCH="${CARCH:-x86_64}"
  set +u
  # shellcheck disable=SC1090
  source "$pkgbuild"
  set -u
  if [[ -n "${saved_carch:-}" ]]; then
    CARCH="$saved_carch"
  else
    unset CARCH
  fi
}

release_tag() {
  printf '%s%s-%s' "$RELEASE_PREFIX" "$pkgver" "$pkgrel"
}

find_pkgfile() {
  local pkgfile
  if [[ -n "${pkgver-}" && -n "${pkgrel-}" ]]; then
    pkgfile=$(ls -1 "$SRC_DIR/${PKGBASE}-${pkgver}-${pkgrel}-"*.pkg.tar.zst 2>/dev/null | grep -v 'mono' | sort | tail -n1 || true)
  else
    pkgfile=$(ls -1 "$SRC_DIR"/*.pkg.tar.zst 2>/dev/null | grep -v 'mono' | sort | tail -n1 || true)
  fi
  [[ -n "$pkgfile" ]] || die "no package artifact found in $SRC_DIR"
  printf '%s' "$pkgfile"
}

find_dist_pkgfile() {
  local pkgfile
  if [[ -n "${pkgver-}" && -n "${pkgrel-}" ]]; then
    pkgfile=$(ls -1 "$DIST_DIR/${PKGBASE}-${pkgver}-${pkgrel}-"*.pkg.tar.zst 2>/dev/null | sort | tail -n1 || true)
  else
    pkgfile=$(ls -1 "$DIST_DIR"/*.pkg.tar.zst 2>/dev/null | sort | tail -n1 || true)
  fi
  [[ -n "$pkgfile" ]] || die "no release artifact found in $DIST_DIR"
  printf '%s' "$pkgfile"
}
