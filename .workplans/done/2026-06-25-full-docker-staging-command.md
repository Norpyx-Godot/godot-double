---
status: done
priority: P1
owner: "codex"
updated: 2026-06-25
---

# Full Docker Staging Command

## Goal
- Make the Docker workflow explicitly support one-shot staging of a Godot package update: resolve version, bump metadata, refresh sources, build the package, verify artifacts, and hydrate `godot-double-bin`.

## Scope
### In
- A clear `gdops stage <pkgver> <pkgrel>|latest` command for mutating staging work.
- A matching `gdops docker stage <pkgver> <pkgrel>|latest` wrapper that runs the same process inside Docker.
- Documentation for the intended flow: Docker stage, review, release/commit/push.
- Tests for command dispatch, dry-run, `latest`, and Docker wrapper behavior.

### Out
- Automatic publishing or pushing by default.
- Solving SSH credential forwarding for AUR push inside Docker.
- Full upstream Arch PKGBUILD harvesting.

## Acceptance Criteria
- `./bin/gdops docker stage latest` is the documented one-shot update command.
- Stage output leaves source package metadata, built artifacts, `dist/`, and binary package metadata ready for release review.
- Existing `validate` and `ci` commands keep working.
- Dry-run stage output uses the resolved target version consistently.
- Tests and coverage pass.

## Decisions
- 2026-06-25:
  - `stage` is the explicit mutating command name; `validate` remains for compatibility and delegates to the same staged behavior.
  - Push/release remain separate because they require credentials and external side effects.

## Verification
- 2026-06-25:
  - `./tests/run.sh` passed.
  - `./tests/coverage.sh` passed with line coverage `292/340` (`85.9%`) for the validation/staging surface.
  - `./bin/gdops --dry-run stage latest` passed and resolved `latest` to `4.7-1`.
  - `./bin/gdops --dry-run docker stage latest` passed.
  - `GDOPS_DOCKER_NO_BUILD=1 ./bin/gdops docker stage --dry-run latest` passed inside the container.
  - `./bin/gdops all --dry-run 4.6.3 0` still passed.
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh` passed.
