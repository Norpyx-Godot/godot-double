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
ARCH_SRC_DIR="${ARCH_SRC_DIR:-$DIST_DIR/arch-packages}"
GH_REPO="${GH_REPO:-}"
RELEASE_PREFIX="${RELEASE_PREFIX:-v}"
AUR_REMOTE="${AUR_REMOTE:-origin}"
MAKEPKG_ARGS="${MAKEPKG_ARGS:--si}"
DRY_RUN="${DRY_RUN:-0}"

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

run_cmd_str() {
  local cmd="$*"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$cmd"
    return 0
  fi
  bash -c "$cmd"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

require_file() {
  [[ -f "$1" ]] || die "missing file: $1"
}

require_dirs() {
  [[ -d "$SRC_DIR" ]] || die "missing submodule: $SRC_DIR"
  [[ -d "$BIN_DIR" ]] || die "missing submodule: $BIN_DIR"
}

require_pkg_metadata() {
  require_dirs
  require_file "$SRC_DIR/PKGBUILD"
  require_file "$SRC_DIR/.SRCINFO"
  require_file "$BIN_DIR/PKGBUILD"
  require_file "$BIN_DIR/.SRCINFO"
}

validate_pkgver_arg() {
  local value="$1"
  [[ "$value" =~ ^[0-9][A-Za-z0-9._+]*$ ]] || die "invalid pkgver: $value"
}

validate_pkgrel_arg() {
  local value="$1"
  [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "invalid pkgrel: $value"
}

validate_bump_args() {
  validate_pkgver_arg "$1"
  validate_pkgrel_arg "$2"
}

arch_package_version() {
  local package="$1"
  local version

  version="$(
    LC_ALL=C pacman -Si "$package" 2>/dev/null |
      awk -F: '/^Version[[:space:]]*:/ { sub(/^[[:space:]]+/, "", $2); print $2; exit }'
  )"
  [[ -n "$version" ]] || die "could not determine Arch package version for $package"
  printf '%s\n' "$version"
}

split_arch_version() {
  local arch_version="$1"
  local version_no_epoch pkgrel_part pkgver_part

  version_no_epoch="${arch_version#*:}"
  [[ "$version_no_epoch" == *-* ]] || die "Arch package version lacks pkgrel: $arch_version"

  pkgrel_part="${version_no_epoch##*-}"
  pkgver_part="${version_no_epoch%-"$pkgrel_part"}"
  pkgver_part="${pkgver_part%-}"

  validate_bump_args "$pkgver_part" "$pkgrel_part"
  printf '%s %s\n' "$pkgver_part" "$pkgrel_part"
}

arch_godot_bump_args() {
  require_cmd pacman

  local godot_version godot_mono_version
  godot_version="$(arch_package_version godot)"
  godot_mono_version="$(arch_package_version godot-mono)"

  if [[ "$godot_version" != "$godot_mono_version" ]]; then
    die "Arch package versions differ: godot=$godot_version godot-mono=$godot_mono_version"
  fi

  split_arch_version "$godot_version"
}

resolve_bump_args() {
  if [[ $# -eq 1 && "$1" == "latest" ]]; then
    arch_godot_bump_args
    return 0
  fi

  [[ $# -ge 2 ]] || die "expected <pkgver> <pkgrel> or latest"
  validate_bump_args "$1" "$2"
  printf '%s %s\n' "$1" "$2"
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

  if [[ -n "${GDOPS_EXPECTED_PKGVER:-}" ]]; then
    pkgver="$GDOPS_EXPECTED_PKGVER"
  fi
  if [[ -n "${GDOPS_EXPECTED_PKGREL:-}" ]]; then
    pkgrel="$GDOPS_EXPECTED_PKGREL"
  fi
}

release_tag() {
  printf '%s%s-%s' "$RELEASE_PREFIX" "$pkgver" "$pkgrel"
}

find_pkgfile() {
  find_pkgfile_for "$PKGBASE"
}

find_pkgfile_for() {
  local package_name="$1"
  local pkgfile
  if [[ -n "${pkgver-}" && -n "${pkgrel-}" ]]; then
    pkgfile=$(ls -1 "$SRC_DIR/${package_name}-${pkgver}-${pkgrel}-"*.pkg.tar.zst 2>/dev/null | sort | tail -n1 || true)
  else
    pkgfile=$(ls -1 "$SRC_DIR/${package_name}-"*.pkg.tar.zst 2>/dev/null | sort | tail -n1 || true)
  fi
  [[ -n "$pkgfile" ]] || die "no package artifact found for $package_name in $SRC_DIR"
  printf '%s' "$pkgfile"
}

find_dist_pkgfile() {
  find_dist_pkgfile_for "$PKGBASE"
}

find_dist_pkgfile_for() {
  local package_name="$1"
  local pkgfile
  if [[ -n "${pkgver-}" && -n "${pkgrel-}" ]]; then
    pkgfile=$(ls -1 "$DIST_DIR/${package_name}-${pkgver}-${pkgrel}-"*.pkg.tar.zst 2>/dev/null | sort | tail -n1 || true)
  else
    pkgfile=$(ls -1 "$DIST_DIR/${package_name}-"*.pkg.tar.zst 2>/dev/null | sort | tail -n1 || true)
  fi
  [[ -n "$pkgfile" ]] || die "no release artifact found for $package_name in $DIST_DIR"
  printf '%s' "$pkgfile"
}
