---
status: done
priority: P0
owner: "codex"
updated: 2026-06-28
---

# Force Makepkg Reruns

## Goal
- Make repeated Dockerized update runs idempotent when package artifacts already exist in `godot-double/`.

## Scope
### In
- Add makepkg force mode to the default build arguments.
- Update the regression test and docs.

### Out
- Cleaning source/build directories.
- Changing publish/release behavior.

## Acceptance Criteria
- `./bin/gdops --dry-run build` shows `makepkg -sf --noconfirm`.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Add `-f` to default `MAKEPKG_ARGS`.
- Verify: Dry-run build test asserts forced, noninteractive args.
- Docs: Update README config description.
- Coverage impact: Existing focused test covers the behavior.

## Decisions
- 2026-06-28:
  - Use makepkg force mode because update reruns should replace old local artifacts rather than fail.

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 532/651 81.7%`)
  - `./bin/gdops --dry-run build` showed `makepkg -sf --noconfirm`.
