---
status: done
priority: P2
owner: "codex"
updated: 2026-06-29
---

# AUR Keyword Metadata

## Goal
- Add reviewable keyword metadata for the `godot-double` AUR package bases and a safe command to apply it to AUR.

## Scope
### In
- Define broad and niche package keywords in repo config.
- Add a `gdops aur-keywords` command that calls AUR's `set-keywords`.
- Add tests and docs.

### Out
- Adding unsupported `keywords=()` arrays to PKGBUILD files.
- Applying keywords remotely during implementation.
- Committing before review.

## Acceptance Criteria
- Keyword lists are visible in the repository for review.
- `./bin/gdops aur-keywords --dry-run` shows both AUR package bases and keyword lists.
- The command can apply keywords to both `godot-double` and `godot-double-bin`.
- Tests and coverage pass.

## Notes / Context
- `makepkg --printsrcinfo` drops a `keywords=()` PKGBUILD variable.
- `man PKGBUILD` does not list `keywords` as a standard PKGBUILD directive.
- `ssh aur@aur.archlinux.org help` exposes `set-keywords <name> [...]`.

## Plan
### Step 1
- Do: Add keyword arrays to config.
- Verify: Dry-run output includes broad and niche terms.
- Docs: Document why this is AUR-side metadata, not PKGBUILD metadata.
- Coverage impact: New command tests cover config usage.

### Step 2
- Do: Add `gdops aur-keywords` command.
- Verify: Stub `ssh` and assert both package bases are updated.
- Docs: Document review/apply flow.
- Coverage impact: Add script to coverage gate.

## Decisions
- 2026-06-29:
  - Do not add `keywords=()` to PKGBUILD because it is not emitted to `.SRCINFO`.
  - Keep binary-package keywords slightly broader by adding `binary` and `prebuilt`.

## Verification
- 2026-06-29:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 618/752 82.2%`)
  - `./bin/gdops --dry-run aur-keywords` showed both package-base keyword commands without applying them.
