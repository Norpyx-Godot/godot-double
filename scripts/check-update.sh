#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

EXIT_CODE_MODE=0

usage() {
  cat <<'USAGE'
Usage: gdops check-update [--exit-code]

Compares local godot-double and godot-double-bin package versions against the
official Arch godot/godot-mono package version.

Options:
  --exit-code   Predicate mode: exit 0 when update is needed, 1 when current,
                and 2 for check errors.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --exit-code)
      EXIT_CODE_MODE=1
      shift
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

pkgbuild_version() {
  local pkgbuild="$1"
  [[ -f "$pkgbuild" ]] || die "missing PKGBUILD: $pkgbuild"

  (
    set -euo pipefail
    CARCH="${CARCH:-x86_64}"
    set +u
    # shellcheck disable=SC1090
    source "$pkgbuild"
    set -u
    [[ -n "${pkgver:-}" && -n "${pkgrel:-}" ]] || exit 2
    printf '%s %s\n' "$pkgver" "$pkgrel"
  ) || die "could not read pkgver/pkgrel from $pkgbuild"
}

append_reason() {
  local current="$1"
  local addition="$2"

  if [[ -z "$current" ]]; then
    printf '%s\n' "$addition"
  else
    printf '%s,%s\n' "$current" "$addition"
  fi
}

require_dirs

godot_version="$(arch_package_version godot)"
godot_mono_version="$(arch_package_version godot-mono)"
if [[ "$godot_version" != "$godot_mono_version" ]]; then
  die "Arch package versions differ: godot=$godot_version godot-mono=$godot_mono_version"
fi

read -r arch_pkgver arch_pkgrel < <(split_arch_version "$godot_version")
read -r source_pkgver source_pkgrel < <(pkgbuild_version "$SRC_DIR/PKGBUILD")
read -r bin_pkgver bin_pkgrel < <(pkgbuild_version "$BIN_DIR/PKGBUILD")

update_needed=0
reason=""

if [[ "$source_pkgver" != "$arch_pkgver" || "$source_pkgrel" != "$arch_pkgrel" ]]; then
  update_needed=1
  reason="$(append_reason "$reason" source_version_mismatch)"
fi

if [[ "$bin_pkgver" != "$arch_pkgver" || "$bin_pkgrel" != "$arch_pkgrel" ]]; then
  update_needed=1
  reason="$(append_reason "$reason" bin_version_mismatch)"
fi

if [[ -z "$reason" ]]; then
  reason="current"
fi

printf 'arch_version=%s\n' "$godot_version"
printf 'arch_pkgver=%s\n' "$arch_pkgver"
printf 'arch_pkgrel=%s\n' "$arch_pkgrel"
printf 'godot=%s\n' "$godot_version"
printf 'godot-mono=%s\n' "$godot_mono_version"
printf 'source_pkgver=%s\n' "$source_pkgver"
printf 'source_pkgrel=%s\n' "$source_pkgrel"
printf 'bin_pkgver=%s\n' "$bin_pkgver"
printf 'bin_pkgrel=%s\n' "$bin_pkgrel"
printf 'update_needed=%s\n' "$update_needed"
printf 'reason=%s\n' "$reason"

if [[ "$EXIT_CODE_MODE" -eq 1 ]]; then
  if [[ "$update_needed" -eq 1 ]]; then
    exit 0
  fi
  exit 1
fi
