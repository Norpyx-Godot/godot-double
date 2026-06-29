---
status: done
priority: P1
owner: "codex"
updated: 2026-06-28
---

# Check Update Predicate Exit Code

## Goal
- Make `gdops check-update --exit-code` behave like a shell predicate: success means an update is needed.

## Scope
### In
- Change `check-update --exit-code` exit semantics.
- Update `idle-update` to map the new no-update status to a successful systemd no-op.
- Update tests and docs.

### Out
- Changing default `check-update` report-mode output.
- Changing `idle-update` service exit semantics.

## Acceptance Criteria
- `check-update --exit-code` exits `0` when an update is needed.
- `check-update --exit-code` exits `1` when no update is needed.
- `check-update --exit-code` exits `2` for check/usage errors.
- `idle-update` still exits `0` for no-update no-op.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Update `check-update` predicate exit semantics and usage text.
- Verify: Tests assert update-needed `0`, current `1`, and bad invocation failure.
- Docs: Document the predicate exit code.
- Coverage impact: Existing check-update tests cover the changed branch.

### Step 2
- Do: Update `idle-update` to treat check status `1` as current/no-op and `0` as update-needed.
- Verify: Existing idle-update tests cover current and update-needed paths.
- Docs: No separate idle-update behavior change.
- Coverage impact: Existing idle-update tests cover the changed branch.

## Decisions
- 2026-06-28:
  - Keep default report mode as exit `0` on successful checks.
  - Use `2` for `check-update --exit-code` check errors so scripts can distinguish errors from “already current.”

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 593/723 82.0%`)
  - `./bin/gdops check-update --exit-code` returned `1` for current local 4.7-1 packages.
