---
status: done
priority: P0
owner: "codex"
updated: 2026-06-28
---

# Noninteractive Makepkg Dependency Install

## Goal
- Make the Dockerized update/build flow install makepkg dependencies without an interactive pacman prompt.

## Scope
### In
- Update the default makepkg arguments used by the repo.
- Add a regression test for the dry-run build command.
- Document the noninteractive default.

### Out
- Installing Godot build dependencies on the host.
- Changing release, commit, or push behavior.

## Acceptance Criteria
- `./bin/gdops --dry-run build` shows `makepkg` runs with `--noconfirm`.
- Tests pass.
- Coverage remains above the repo threshold.

## Plan
### Step 1
- Do: Add `--noconfirm` to the default `MAKEPKG_ARGS`.
- Verify: Dry-run build output includes the flag.
- Docs: Update README setup/config docs.
- Coverage impact: Add focused shell test.

## Decisions
- 2026-06-28:
  - Keep dependency installation inside Docker; do not require the host to install makepkg runtime dependencies.
  - Use makepkg's `--noconfirm` flag instead of piping input to pacman.

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 523/637 82.1%`)
  - `docker run --rm --entrypoint bash godot-double-ci:latest -lc 'makepkg --help | grep -F -- --noconfirm'`
