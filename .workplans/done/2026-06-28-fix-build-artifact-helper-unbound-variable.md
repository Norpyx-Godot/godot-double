---
status: done
priority: P0
owner: "codex"
updated: 2026-06-28
---

# Fix Build Artifact Helper Unbound Variable

## Goal
- Remove the `package_name: unbound variable` failure from the resumable build artifact check.

## Scope
### In
- Rewrite the build artifact existence helper without command substitution.
- Add a regression test for package names with hyphenated suffixes.

### Out
- Changing package build behavior beyond the helper implementation.

## Acceptance Criteria
- `build` can check `godot-double-mono` artifacts under `set -u` without failing.
- Existing skip/rebuild behavior remains covered by tests.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Replace the `find` command substitution helper with a direct glob check.
- Verify: Add/keep tests for full and partial artifact sets.
- Docs: No user-facing docs change needed.
- Coverage impact: Existing build tests cover the changed helper.

## Decisions
- 2026-06-28:
  - Prefer a simple nullglob loop over `find` plus command substitution in this small hot path.

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 562/681 82.5%`)
  - `env -u package_name ./bin/gdops --dry-run build` skipped existing 4.7-1 artifacts successfully.
