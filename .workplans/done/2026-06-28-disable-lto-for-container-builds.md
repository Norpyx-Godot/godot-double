---
status: done
priority: P0
owner: "codex"
updated: 2026-06-28
---

# Disable LTO For Container Builds

## Goal
- Prevent the Dockerized Godot build from being killed during final LTO linking.

## Scope
### In
- Update the official Arch PKGBUILD transform to disable makepkg LTO for `godot-double`.
- Add an optional SCons job limiter for constrained Docker Desktop/CI memory.
- Pass the limiter environment variable into Docker.
- Add tests and docs.

### Out
- Changing package outputs or release behavior.
- Installing build dependencies on the host.

## Acceptance Criteria
- Transformed `godot-double/PKGBUILD` contains `options=(!lto)` or equivalent.
- Transformed SCons jobs can be limited with `GDOPS_SCONS_JOBS`.
- Docker wrapper passes `GDOPS_SCONS_JOBS` into the container.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Inject `!lto` into transformed PKGBUILDs.
- Verify: Transform fixture asserts `!lto` exists.
- Docs: Document the LTO rationale.
- Coverage impact: Existing transform test covers this branch.

### Step 2
- Do: Replace fixed `-j$(nproc --all)` with `GDOPS_SCONS_JOBS` fallback.
- Verify: Transform fixture asserts the env fallback exists.
- Docs: Document `GDOPS_SCONS_JOBS`.
- Coverage impact: Existing transform test covers this branch.

### Step 3
- Do: Pass `GDOPS_SCONS_JOBS` through Docker.
- Verify: Dry-run Docker test inspects the env flag.
- Docs: Document the host-side override.
- Coverage impact: Add focused shell test.

## Decisions
- 2026-06-28:
  - Disable makepkg LTO because `lto1` is the process killed during final link.
  - Keep default SCons parallelism unchanged, but expose a limiter for constrained CI/Docker Desktop runs.

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 532/651 81.7%`)
  - `GDOPS_SCONS_JOBS=4 ./bin/gdops --dry-run docker test` showed the environment variable passed into Docker.
