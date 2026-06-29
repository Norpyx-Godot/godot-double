---
status: done
priority: P0
owner: "codex"
updated: 2026-06-28
---

# Publish Mono Release Artifact

## Goal
- Ensure GitHub releases contain both `godot-double` and `godot-double-mono` package artifacts referenced by the generated `-bin` PKGBUILD.

## Scope
### In
- Upload both split package artifacts from `dist/`.
- Make `release` resumable when the GitHub release already exists.
- Add shell tests for create and existing-release upload paths.
- Update docs.

### Out
- Changing package build outputs.
- Automatically pushing AUR repos.

## Acceptance Criteria
- `gdops release` creates a new release with both source artifacts.
- If the release already exists, `gdops release` uploads both artifacts with overwrite semantics.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Update `scripts/release.sh` to locate both dist artifacts.
- Verify: Test dry-run output and stubbed `gh release create`.
- Docs: Mention both release assets.
- Coverage impact: Add release script to coverage gate.

### Step 2
- Do: Add existing-release repair path using `gh release upload --clobber`.
- Verify: Stub `gh release view` success and assert upload invocation.
- Docs: Document resumable release behavior.
- Coverage impact: Tests cover both branches.

## Decisions
- 2026-06-28:
  - Treat existing GitHub releases as resumable state and upload assets with `--clobber`.

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 589/719 81.9%`)
  - `./bin/gdops --dry-run release` showed both `godot-double` and `godot-double-mono` assets.
