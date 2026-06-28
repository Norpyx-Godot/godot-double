#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIRS=()

cleanup() {
  for tmp_dir in "${TMP_DIRS[@]}"; do
    rm -rf "$tmp_dir"
  done
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_success() {
  local output
  output="$("$@" 2>&1)" || fail "expected success: $*"$'\n'"$output"
}

assert_failure() {
  local output
  if output="$("$@" 2>&1)"; then
    fail "expected failure: $*"$'\n'"$output"
  fi
}

make_fixture() {
  local fixture
  fixture="$(mktemp -d)"
  TMP_DIRS+=("$fixture")

  mkdir -p "$fixture/godot-double" "$fixture/godot-double-bin" "$fixture/dist"

  cat > "$fixture/godot-double/PKGBUILD" <<'EOF'
pkgbase=godot-double
pkgname=(godot-double godot-double-mono)
pkgver=1.2.3
pkgrel=4
pkgdesc='Fixture package'
url='https://example.invalid/'
license=(MIT)
arch=(x86_64)
source=("fixture-${pkgver}.tar.gz")
sha256sums=('SKIP')

package_godot-double() {
  :
}
EOF

  cat > "$fixture/godot-double/.SRCINFO" <<'EOF'
pkgbase = godot-double
	pkgver = 1.2.3
	pkgrel = 4
EOF

  cat > "$fixture/godot-double-bin/PKGBUILD" <<'EOF'
pkgname=godot-double-bin
pkgver=1.2.3
pkgrel=4
pkgdesc='Fixture binary package'
arch=(x86_64)
url='https://example.invalid/'
license=(MIT)
provides=("godot-double")
conflicts=("godot-double")
source=("godot-double-1.2.3-4-x86_64.pkg.tar.zst::https://example.invalid/godot-double-1.2.3-4-x86_64.pkg.tar.zst")
noextract=("godot-double-1.2.3-4-x86_64.pkg.tar.zst")
sha256sums=('SKIP')

package() {
  :
}
EOF

  cat > "$fixture/godot-double-bin/.SRCINFO" <<'EOF'
pkgbase = godot-double-bin
	pkgver = 1.2.3
	pkgrel = 4
EOF

  printf '%s\n' "$fixture"
}

gdops_fixture() {
  local fixture="$1"
  shift

  SRC_DIR="$fixture/godot-double" \
  BIN_DIR="$fixture/godot-double-bin" \
  DIST_DIR="$fixture/dist" \
    "$ROOT_DIR/bin/gdops" "$@"
}

make_makepkg_stub() {
  local output="$1"
  local stub_dir
  stub_dir="$(mktemp -d)"
  TMP_DIRS+=("$stub_dir")

  cat > "$stub_dir/makepkg" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" == "--printsrcinfo" ]]; then
  cat <<'SRCINFO'
$output
SRCINFO
  exit 0
fi
printf 'unexpected makepkg args: %s\n' "\$*" >&2
exit 1
EOF
  chmod +x "$stub_dir/makepkg"
  printf '%s\n' "$stub_dir"
}

make_command_stub_dir() {
  local stub_dir cmd
  stub_dir="$(mktemp -d)"
  TMP_DIRS+=("$stub_dir")

  for cmd in "$@"; do
    cat > "$stub_dir/$cmd" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$stub_dir/$cmd"
  done

  printf '%s\n' "$stub_dir"
}

make_pacman_stub_dir() {
  local godot_version="$1"
  local godot_mono_version="$2"
  local stub_dir
  stub_dir="$(mktemp -d)"
  TMP_DIRS+=("$stub_dir")

  cat > "$stub_dir/pacman" <<EOF
#!/usr/bin/env bash
set -euo pipefail

if [[ "\${1:-}" != "-Si" ]]; then
  printf 'unexpected pacman args: %s\n' "\$*" >&2
  exit 1
fi

case "\${2:-}" in
  godot)
    version="$godot_version"
    ;;
  godot-mono)
    version="$godot_mono_version"
    ;;
  *)
    exit 1
    ;;
esac

cat <<PACMAN
Repository      : extra
Name            : \${2:-}
Version         : \$version
PACMAN
EOF

  chmod +x "$stub_dir/pacman"
  printf '%s\n' "$stub_dir"
}

make_package_tool_stub_dir() {
  local stub_dir
  stub_dir="$(mktemp -d)"
  TMP_DIRS+=("$stub_dir")

  cat > "$stub_dir/updpkgsums" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  cat > "$stub_dir/makepkg" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--printsrcinfo" ]]; then
  case "$(basename "$PWD")" in
    godot-double)
      cat <<'SRCINFO'
pkgbase = godot-double
	pkgver = 1.2.3
	pkgrel = 4
SRCINFO
      ;;
    godot-double-bin)
      cat <<'SRCINFO'
pkgbase = godot-double-bin
	pkgver = 1.2.3
	pkgrel = 4
SRCINFO
      ;;
    *)
      exit 1
      ;;
  esac
  exit 0
fi

printf 'fixture artifact\n' > godot-double-1.2.3-4-x86_64.pkg.tar.zst
printf 'fixture mono artifact\n' > godot-double-mono-1.2.3-4-x86_64.pkg.tar.zst
EOF

  chmod +x "$stub_dir/updpkgsums" "$stub_dir/makepkg"
  printf '%s\n' "$stub_dir"
}

make_pkgctl_stub_dir() {
  local stub_dir
  stub_dir="$(mktemp -d)"
  TMP_DIRS+=("$stub_dir")

  cat > "$stub_dir/pkgctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "repo" || "${2:-}" != "clone" || "${3:-}" != "--protocol=https" || "${4:-}" != "godot" ]]; then
  printf 'unexpected pkgctl args: %s\n' "$*" >&2
  exit 1
fi

mkdir -p godot
cat > godot/PKGBUILD <<'PKGBUILD'
pkgbase=godot
pkgname=(godot godot-mono)
pkgver=1.2.3
pkgrel=4
pkgdesc='Advanced cross-platform 2D and 3D game engine'
url='https://godotengine.org/'
license=(MIT)
arch=(x86_64)
makedepends=(scons setconf)
depends=(freetype2 libglvnd)
optdepends=('pipewire-alsa: for audio support')
source=("git+https://github.com/godotengine/godot#tag=$pkgver-stable")
b2sums=('SKIP')

prepare() {
  cd $pkgname
}

case $CARCH in
  x86_64*) _CARCH=x86_64;;
esac

build() {
  cd $pkgname
  _args=(
    pulseaudio=yes
  )
  scons "${_args[@]}"
  _args+=(module_mono_enabled=yes mono_glue=no)
  scons "${_args[@]}"
  bin/godot.linuxbsd.editor.$_CARCH.mono --headless --generate-mono-glue modules/mono/glue
  modules/mono/build_scripts/build_assemblies.py --godot-output-dir=./bin --godot-platform=linuxbsd
}

package_godot() {
  cd $pkgbase
}
PKGBUILD
EOF

  chmod +x "$stub_dir/pkgctl"
  printf '%s\n' "$stub_dir"
}

test_preflight_rejects_invalid_version() {
  local fixture
  fixture="$(make_fixture)"

  assert_failure gdops_fixture "$fixture" --dry-run preflight "bad version" 4
}

test_preflight_passes_with_required_tools() {
  local fixture stub_dir
  fixture="$(make_fixture)"
  stub_dir="$(make_command_stub_dir git makepkg updpkgsums sha256sum)"

  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" preflight 1.2.3 4
}

test_preflight_requires_metadata() {
  local fixture
  fixture="$(make_fixture)"
  rm "$fixture/godot-double/.SRCINFO"

  assert_failure gdops_fixture "$fixture" --dry-run preflight 1.2.3 4
}

test_bump_check_matches_pkgbuild() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" bump-check 1.2.3 4
  assert_failure gdops_fixture "$fixture" bump-check 1.2.4 4
}

test_metadata_check_detects_srcinfo_drift() {
  local fixture stub_dir
  fixture="$(make_fixture)"

  stub_dir="$(make_makepkg_stub "$(cat "$fixture/godot-double/.SRCINFO")")"
  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" metadata-check source

  stub_dir="$(make_makepkg_stub "pkgbase = godot-double
	pkgver = 9.9.9
	pkgrel = 1")"
  PATH="$stub_dir:$PATH" assert_failure gdops_fixture "$fixture" metadata-check source
}

test_metadata_check_supports_binary_repo() {
  local fixture stub_dir
  fixture="$(make_fixture)"

  stub_dir="$(make_makepkg_stub "$(cat "$fixture/godot-double-bin/.SRCINFO")")"
  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" metadata-check bin
}

test_artifact_check_passes_for_expected_artifact() {
  local fixture artifact mono_artifact
  fixture="$(make_fixture)"
  artifact="$fixture/godot-double/godot-double-1.2.3-4-x86_64.pkg.tar.zst"
  mono_artifact="$fixture/godot-double/godot-double-mono-1.2.3-4-x86_64.pkg.tar.zst"
  printf 'fixture artifact\n' > "$artifact"
  printf 'fixture mono artifact\n' > "$mono_artifact"

  assert_success gdops_fixture "$fixture" artifact-check
}

test_arch_latest_reports_aligned_versions() {
  local fixture stub_dir
  fixture="$(make_fixture)"
  stub_dir="$(make_pacman_stub_dir 4.7-1 4.7-1)"

  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" arch-latest
}

test_arch_latest_rejects_mismatched_versions() {
  local fixture stub_dir
  fixture="$(make_fixture)"
  stub_dir="$(make_pacman_stub_dir 4.7-1 4.6.3-1)"

  PATH="$stub_dir:$PATH" assert_failure gdops_fixture "$fixture" arch-latest
}

test_arch_latest_rejects_invalid_arch_version() {
  local fixture stub_dir
  fixture="$(make_fixture)"
  stub_dir="$(make_pacman_stub_dir 4.7 4.7)"

  PATH="$stub_dir:$PATH" assert_failure gdops_fixture "$fixture" arch-latest
}

test_stage_usage_and_argument_errors() {
  local fixture cmd
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --help
  for cmd in arch-latest update sync-arch-pkgbuild preflight bump-check metadata-check stage validate source-check artifact-check hydrate-check test ci docker; do
    assert_success gdops_fixture "$fixture" "$cmd" --help
  done

  assert_failure gdops_fixture "$fixture" update latest extra
  assert_failure gdops_fixture "$fixture" update 1.2.3
  assert_failure gdops_fixture "$fixture" source-check extra
  assert_failure gdops_fixture "$fixture" artifact-check extra
  assert_failure gdops_fixture "$fixture" hydrate-check extra
  assert_failure gdops_fixture "$fixture" stage 1.2.3 4 extra
  assert_failure gdops_fixture "$fixture" validate 1.2.3 4 extra
  assert_failure gdops_fixture "$fixture" ci 1.2.3 4 extra
  assert_failure gdops_fixture "$fixture" docker build extra
  assert_failure gdops_fixture "$fixture" docker test extra
  assert_failure gdops_fixture "$fixture" docker shell extra
  assert_failure gdops_fixture "$fixture" docker unknown
}

test_validate_dry_run_accepts_new_version() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run validate 2.0.0 1
}

test_stage_dry_run_accepts_new_version() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run stage 2.0.0 1
}

test_sync_arch_pkgbuild_dry_run() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run sync-arch-pkgbuild
}

test_sync_arch_pkgbuild_transforms_official_pkgbuild() {
  local fixture stub_dir transformed
  fixture="$(make_fixture)"
  stub_dir="$(make_pkgctl_stub_dir)"

  PATH="$stub_dir:$PATH" ARCH_SRC_DIR="$fixture/arch-src" assert_success gdops_fixture "$fixture" sync-arch-pkgbuild

  transformed="$fixture/godot-double/PKGBUILD"
  grep -q '^pkgbase=godot-double$' "$transformed" || fail "pkgbase was not transformed"
  grep -q '^pkgname=(godot-double godot-double-mono)$' "$transformed" || fail "pkgname was not transformed"
  grep -q 'precision=double' "$transformed" || fail "double precision flag was not added"
  grep -q 'package_godot-double()' "$transformed" || fail "godot-double package function missing"
  grep -q 'package_godot-double-mono()' "$transformed" || fail "godot-double-mono package function missing"
}

test_stage_passes_with_stubbed_package_tools() {
  local fixture pkg_stub_dir pkgctl_stub_dir
  fixture="$(make_fixture)"
  pkg_stub_dir="$(make_package_tool_stub_dir)"
  pkgctl_stub_dir="$(make_pkgctl_stub_dir)"

  PATH="$pkg_stub_dir:$pkgctl_stub_dir:$PATH" ARCH_SRC_DIR="$fixture/arch-src" assert_success gdops_fixture "$fixture" stage 1.2.3 4

  grep -q '^pkgname=(godot-double-bin godot-double-mono-bin)$' "$fixture/godot-double-bin/PKGBUILD" ||
    fail "binary split package names were not generated"
  grep -q '^package_godot-double-mono-bin()' "$fixture/godot-double-bin/PKGBUILD" ||
    fail "godot-double-mono-bin package function was not generated"
}

test_ci_dry_run_accepts_new_version() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run ci 2.0.0 1
}

test_ci_dry_run_accepts_latest() {
  local fixture stub_dir
  fixture="$(make_fixture)"
  stub_dir="$(make_pacman_stub_dir 4.7-1 4.7-1)"

  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" --dry-run ci latest
}

test_stage_dry_run_accepts_latest() {
  local fixture stub_dir
  fixture="$(make_fixture)"
  stub_dir="$(make_pacman_stub_dir 4.7-1 4.7-1)"

  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" --dry-run stage latest
}

test_docker_validate_dry_run_does_not_require_docker() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run docker stage 2.0.0 1
  assert_success gdops_fixture "$fixture" --dry-run docker stage latest
  assert_success gdops_fixture "$fixture" --dry-run docker validate 2.0.0 1
  assert_success gdops_fixture "$fixture" --dry-run docker validate latest
}

test_docker_build_test_and_shell_dry_run_do_not_require_docker() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run docker build
  assert_success gdops_fixture "$fixture" --dry-run docker test
  assert_success gdops_fixture "$fixture" --dry-run docker shell
}

test_docker_commands_support_stubbed_docker() {
  local fixture stub_dir
  fixture="$(make_fixture)"
  stub_dir="$(make_command_stub_dir docker)"

  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" docker build
  PATH="$stub_dir:$PATH" assert_success gdops_fixture "$fixture" docker test
  PATH="$stub_dir:$PATH" GDOPS_DOCKER_NO_BUILD=1 assert_success gdops_fixture "$fixture" docker stage 2.0.0 1
  PATH="$stub_dir:$PATH" GDOPS_DOCKER_NO_BUILD=1 assert_success gdops_fixture "$fixture" docker stage latest
  PATH="$stub_dir:$PATH" GDOPS_DOCKER_NO_BUILD=1 assert_success gdops_fixture "$fixture" docker validate 2.0.0 1
  PATH="$stub_dir:$PATH" GDOPS_DOCKER_NO_BUILD=1 assert_success gdops_fixture "$fixture" docker validate latest
  PATH="$stub_dir:$PATH" GDOPS_DOCKER_NO_BUILD=1 assert_success gdops_fixture "$fixture" docker ci 2.0.0 1
  PATH="$stub_dir:$PATH" GDOPS_DOCKER_NO_BUILD=1 assert_success gdops_fixture "$fixture" docker ci latest
  PATH="$stub_dir:$PATH" GDOPS_DOCKER_NO_BUILD=1 assert_success gdops_fixture "$fixture" docker shell
}

test_docker_ci_dry_run_does_not_require_docker() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run docker ci 2.0.0 1
  assert_success gdops_fixture "$fixture" --dry-run docker ci latest
}

test_update_dry_run_defaults_to_latest() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run update
}

test_update_dry_run_accepts_latest_and_explicit_version() {
  local fixture
  fixture="$(make_fixture)"

  assert_success gdops_fixture "$fixture" --dry-run update latest
  assert_success gdops_fixture "$fixture" --dry-run update 2.0.0 1
}

test_preflight_rejects_invalid_version
test_preflight_passes_with_required_tools
test_preflight_requires_metadata
test_bump_check_matches_pkgbuild
test_metadata_check_detects_srcinfo_drift
test_metadata_check_supports_binary_repo
test_artifact_check_passes_for_expected_artifact
test_arch_latest_reports_aligned_versions
test_arch_latest_rejects_mismatched_versions
test_arch_latest_rejects_invalid_arch_version
test_stage_usage_and_argument_errors
test_validate_dry_run_accepts_new_version
test_stage_dry_run_accepts_new_version
test_sync_arch_pkgbuild_dry_run
test_sync_arch_pkgbuild_transforms_official_pkgbuild
test_stage_passes_with_stubbed_package_tools
test_ci_dry_run_accepts_new_version
test_ci_dry_run_accepts_latest
test_stage_dry_run_accepts_latest
test_docker_validate_dry_run_does_not_require_docker
test_docker_build_test_and_shell_dry_run_do_not_require_docker
test_docker_commands_support_stubbed_docker
test_docker_ci_dry_run_does_not_require_docker
test_update_dry_run_defaults_to_latest
test_update_dry_run_accepts_latest_and_explicit_version
