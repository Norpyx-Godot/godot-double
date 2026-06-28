---
status: done
priority: P2
owner: "codex"
updated: 2026-06-25
---

# Arch Package Latest Version Resolution

## Goal
- Replace the manual "check latest Godot upstream release" step with a CI-compatible Arch package version resolver based on official `pacman` metadata for `godot` and `godot-mono`.

## Scope
### In
- A `gdops` command that reports the current Arch `godot`/`godot-mono` package version.
- Support for `latest` in validation/CI commands so Docker CI can validate the current Arch-packaged Godot version without manual copy/paste.
- Documentation and tests for aligned/mismatched package versions.

### Out
- Full automatic harvesting of Arch PKGBUILDs.
- Using `yay` as a required dependency.
- Publishing or pushing release artifacts automatically.

## Acceptance Criteria
- `./bin/gdops arch-latest` prints the Arch package version split into `pkgver` and `pkgrel`.
- `./bin/gdops ci latest` and `./bin/gdops validate latest` resolve through the same Arch package version check.
- `godot` and `godot-mono` must agree on version; mismatches fail the gate.
- Docker CI can call `./bin/gdops docker ci latest`.
- README no longer says to check the latest upstream release manually.
- Tests cover success, mismatch, invalid version format, and dry-run command paths.

## Decisions
- 2026-06-25:
  - `pacman` is the source of truth for the first implementation because the target baseline is Arch's official `godot` and `godot-mono` packages.
  - `yay` is not required because it is an AUR helper and adds no value for official repo package version discovery.
  - This does not imply full PKGBUILD harvesting yet; it only automates version selection.

## Verification
- 2026-06-25:
  - `./bin/gdops arch-latest` reported `arch_version=4.7-1`, `pkgver=4.7`, and `pkgrel=1`.
  - `./bin/gdops --dry-run ci latest` passed and carried `4.7-1` through artifact/hydration dry-run output.
  - `./bin/gdops --dry-run docker ci latest` passed.
  - `GDOPS_DOCKER_NO_BUILD=1 ./bin/gdops docker ci --dry-run latest` passed inside the container.
  - `./tests/run.sh` passed.
  - `./tests/coverage.sh` passed with line coverage `278/324` (`85.8%`) for the validation surface.
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh` passed.
