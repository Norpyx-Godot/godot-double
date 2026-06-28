---
status: done
priority: P0
owner: "codex"
updated: 2026-06-28
---

# Resume From Built Artifacts

## Goal
- Let `gdops update` continue when the expected package artifacts are already present from a previous successful or partially successful run.

## Scope
### In
- Make the build step skip `makepkg` when both expected split package artifacts already exist.
- Keep forced makepkg reruns for partial artifact states.
- Add tests and docs.

### Out
- Trusting incomplete single-artifact states.
- Publishing or pushing automatically.

## Acceptance Criteria
- `build` skips makepkg when both `godot-double` and `godot-double-mono` artifacts for the target version exist.
- `build` still runs `makepkg -sf --noconfirm` when artifacts are missing.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Teach `scripts/build.sh` to detect complete existing artifact sets.
- Verify: Add tests for full artifact skip and missing artifact build.
- Docs: Document idempotent/resumable build behavior.
- Coverage impact: Focused shell tests cover the branch.

## Decisions
- 2026-06-28:
  - Skip only when both split source artifacts exist and are nonempty.
  - Keep `-f` in default makepkg args so partial states are recoverable.

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 555/680 81.6%`)
  - `./bin/gdops --dry-run build` skipped the existing 4.7-1 artifacts in the live tree.
