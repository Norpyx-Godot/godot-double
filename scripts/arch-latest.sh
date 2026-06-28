#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'USAGE'
Usage: gdops arch-latest

Reports the latest Arch official repo version shared by godot and godot-mono.
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

godot_version="$(arch_package_version godot)"
godot_mono_version="$(arch_package_version godot-mono)"

if [[ "$godot_version" != "$godot_mono_version" ]]; then
  die "Arch package versions differ: godot=$godot_version godot-mono=$godot_mono_version"
fi

read -r pkgver_latest pkgrel_latest < <(split_arch_version "$godot_version")

printf 'arch_version=%s\n' "$godot_version"
printf 'pkgver=%s\n' "$pkgver_latest"
printf 'pkgrel=%s\n' "$pkgrel_latest"
printf 'godot=%s\n' "$godot_version"
printf 'godot-mono=%s\n' "$godot_mono_version"
