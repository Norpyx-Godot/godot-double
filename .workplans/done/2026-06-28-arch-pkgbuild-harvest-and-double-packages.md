---
status: done
priority: P1
owner: "codex"
updated: 2026-06-28
---

# Arch PKGBUILD Harvest And Double Packages

## Goal
- Make `gdops update` harvest official Arch Linux `godot` and `godot-mono` package sources, transform them into the double-precision package set, test, and build inside Docker.

## Scope
### In
- Fix Docker so `makepkg -s` can resolve and install dependencies.
- Add an official Arch package source fetch step for `godot` and `godot-mono`.
- Add an initial transformation path for package names, conflicts/provides, source metadata, build flags, executable names, desktop metadata, and binary package hydration.
- Preserve the maintainer flow: `./bin/gdops update`, then `commit`, then `push`.
- Extend tests/docs for the new direction.

### Out
- Automatic publish/push by default.
- Perfect long-term PKGBUILD semantic merging in this first pass.
- Solving older-glibc runtime portability, which remains in the portable-runtime workplan.

## Acceptance Criteria
- Docker builds retain pacman repository metadata so `makepkg -s` can install missing dependencies.
- `gdops update` can run in Docker with dependencies resolvable.
- A command exists to fetch official Arch `godot` and `godot-mono` PKGBUILDs.
- The update flow is documented as:
  - fetch official package sources,
  - transform to double-precision packages,
  - run tests,
  - build,
  - hydrate binary package metadata.
- Tests cover the Docker dependency fix and the initial official-source fetch/transform command behavior.

## Open Questions
- Should `godot-double` remain one split package that produces `godot-double` and `godot-double-mono`, or should the repo split source packages to mirror Arch's separate `godot` and `godot-mono` packages?
- Should `godot-double-bin` become a split binary package that produces `godot-double-bin` and `godot-double-mono-bin`, or should `godot-double-mono-bin` be a separate AUR repo?

## Decisions
- 2026-06-28:
  - Immediate Docker dependency resolution is a bug fix and should land before full PKGBUILD harvesting is complete.
  - Publishing remains explicit: `update`, review, `release`, `commit`, `push`.
  - Official Arch currently uses one `godot` split-package PKGBUILD for both `godot` and `godot-mono`, so the sync step fetches `godot` and transforms that split package rather than cloning a separate `godot-mono` package base.

## Verification
- 2026-06-28:
  - `./tests/run.sh` passed.
  - `./tests/coverage.sh` passed with line coverage `358/438` (`81.7%`) for the update/validation/staging surface.
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh` passed.
  - `./bin/gdops --dry-run stage latest` passed and showed official-source sync plus both source artifacts.
  - `./bin/gdops docker build` passed with `devtools` installed and pacman sync DBs retained.
  - In the rebuilt Docker image, `pacman -Sp --noconfirm --needed embree freetype2 graphite libglvnd libspeechd libsquish libtheora libvorbis libwebp libwslay libxcursor libxi libxinerama libxrandr miniupnpc openxr` resolved successfully.
  - A fixture run of `sync-arch-pkgbuild` inside Docker cloned the official Arch `godot` package source and generated a double-precision split PKGBUILD.
  - `makepkg --printsrcinfo` succeeded against the generated double-precision PKGBUILD.
  - `GDOPS_DOCKER_NO_BUILD=1 ./bin/gdops docker ci --dry-run latest` passed inside the rebuilt container.
