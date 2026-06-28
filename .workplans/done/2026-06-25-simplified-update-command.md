---
status: done
priority: P1
owner: "codex"
updated: 2026-06-25
---

# Simplified Update Command

## Goal
- Make the maintainer flow simple: run one update command, then commit and push.

## Scope
### In
- Add `gdops update` as the primary Docker-backed command.
- Default `gdops update` to the latest Arch `godot`/`godot-mono` version.
- Keep explicit version support for overrides.
- Update docs/tests so the normal workflow is `update`, `commit`, `push`.

### Out
- Removing lower-level stage/validate/ci commands.
- Automatic publish/push by default.

## Acceptance Criteria
- `./bin/gdops update` runs the Dockerized test-plus-stage path for `latest`.
- `./bin/gdops update <pkgver> <pkgrel>` supports explicit overrides.
- `./bin/gdops --dry-run update` shows the Docker command that would run.
- README presents `update`, `commit`, `push` as the normal flow.
- Tests and coverage pass.

## Decisions
- 2026-06-25:
  - `update` delegates to Docker `ci` so tests/coverage run before staging.
  - Commit/push remain separate because they publish repository state.

## Verification
- 2026-06-25:
  - `./tests/run.sh` passed.
  - `./tests/coverage.sh` passed with line coverage `314/363` (`86.5%`) for the update/validation/staging surface.
  - `./bin/gdops --dry-run update` passed and resolved to Docker `ci latest`.
  - `./bin/gdops --dry-run update 4.7 1` passed.
  - `GDOPS_DOCKER_NO_BUILD=1 ./bin/gdops docker ci --dry-run latest` passed inside the container.
  - `./bin/gdops --help` and `./bin/gdops update --help` passed.
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh` passed.
