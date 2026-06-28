---
status: ready
priority: P1
owner: "codex"
updated: 2026-02-09
---

# Portable Linux Runtime For Release Artifacts

## Goal
- Make the GitHub release artifact (`godot-double-<ver>-<rel>-x86_64.pkg.tar.zst`) runnable on older Linux systems by eliminating missing shared-library failures and by lowering the minimum required glibc version.

## Scope
### In
- `godot-double/PKGBUILD` linker/input-library choices that control runtime dynamic dependencies.
- Build/release automation scripts in `scripts/` and `bin/gdops`.
- Runtime compatibility validation added to the release workflow.
- End-user and contributor docs for release expectations and validation.

### Out
- Upstream Godot source code changes.
- Windows/macOS distribution changes.
- Mono runtime portability for this first pass (tracked separately if needed).

## Acceptance Criteria
- A release artifact built by this repo passes runtime audit checks:
  - `ldd` reports no `not found` entries for required runtime libs.
  - Maximum required glibc symbol version is `GLIBC_2.28` or lower.
- In a glibc 2.28 environment, running extracted `/usr/bin/godot-double --version` succeeds.
- `./bin/gdops build` fails fast when runtime audit checks fail.
- `./bin/gdops all --dry-run <ver> <rel>` still works after workflow changes.
- `README.md` documents runtime compatibility guarantees and validation commands.

## Notes / Context (what was learned from reading the code)
- Source package build options in `godot-double/PKGBUILD` explicitly disable many builtins (`builtin_libtheora=no`, `builtin_miniupnpc=no`, `builtin_embree=no`, `builtin_openxr=no`, etc.), which drives dynamic links to system libraries.
- Release artifacts are built from local `makepkg` output and published directly (`scripts/build.sh` -> `scripts/hydrate-bin.sh` -> `scripts/release.sh`) with no compatibility gate.
- Current artifacts in this repo were built on a very new Arch environment (`.BUILDINFO` includes `glibc-2.42`), which explains high runtime glibc requirements on older distros.
- The reported failure pattern (`libtheoradec.so.2` not found, `libminiupnpc.so.19` not found, `libembree4.so.4` not found, `libopenxr_loader.so.1` not found, and `GLIBC_2.38` mismatch) matches the current dynamic-linking/build-host behavior.

## Plan (steps)
### Step 1
- Do: Add a runtime audit script (for example, `scripts/audit-runtime.sh`) that inspects the built package artifact, extracts `usr/bin/godot-double`, and checks both unresolved shared libs and max required glibc symbol version.
- Verify:
  - Run audit against the current artifact and confirm it reproduces known failures.
  - Run audit on a passing artifact and confirm zero unresolved libs plus glibc threshold compliance.
- Docs:
  - Add a short "Runtime audit" section to `README.md` with command usage.
- Coverage impact:
  - Add tests for audit pass/fail parsing and threshold checks.

### Step 2
- Do: Adjust `godot-double/PKGBUILD` build/link configuration to reduce externally required runtime libs for release artifacts (prefer builtins or static linkage where appropriate), and update package dependency declarations accordingly.
- Verify:
  - Build with `makepkg`.
  - Re-run runtime audit; confirm no unexpected `not found` libraries.
  - Validate that installed package metadata (`.PKGINFO`) remains accurate for remaining dynamic deps.
- Docs:
  - Document selected linking policy and resulting runtime dependency model in `README.md`.
- Coverage impact:
  - Extend tests to validate dependency-audit expectations from built metadata.

### Step 3
- Do: Add a portable-build path that pins an older build environment for release artifact creation (targeting glibc 2.28 compatibility, aligned with upstream Godot Linux release policy), and integrate it into the documented release workflow.
- Verify:
  - Produce an artifact from the pinned environment.
  - Confirm `GLIBC_2.28` (or lower) maximum requirement via the audit script.
  - Confirm `godot-double --version` runs in a glibc 2.28 runtime environment.
- Docs:
  - Add contributor setup instructions for the pinned build environment and explain why this is required.
- Coverage impact:
  - Add automated checks for build-environment guardrails (for example, expected container/chroot image tag detection).

### Step 4
- Do: Wire runtime audit into the release pipeline so release creation is blocked when compatibility checks fail.
- Verify:
  - Negative test: intentionally failing artifact stops before `gh release create`.
  - Positive test: passing artifact proceeds through hydrate/release path.
- Docs:
  - Update `README.md` "Typical Release Flow" to include the new gate.
- Coverage impact:
  - Add tests for gate wiring in `build`/`all` script flows.

### Step 5
- Do: Add/refresh test and coverage tooling for changed shell scripts and document canonical commands in the repo.
- Verify:
  - Test suite passes locally for changed automation scripts.
  - Coverage report meets line >= 80% and branch >= 70% for touched script paths.
- Docs:
  - Record canonical commands in `README.md`:
    - Tests: `<fill>`
    - Coverage: `<fill>`
    - Docs build: `<fill>`
- Coverage impact:
  - Enforces repo policy targets for this change set.

## Open Questions
- Should this workplan include `godot-double-mono` runtime portability now, or track it as a follow-up workplan?
- Which external runtime libs (if any) are intentionally allowed to remain dynamic after portability work?

## Decisions
- 2026-02-09:
  - This workplan targets the non-Mono `godot-double` release artifact first.
  - Runtime compatibility will be treated as a release-blocking requirement, not a best-effort check.
  - Minimum glibc compatibility target is set to `GLIBC_2.28`, aligned with upstream Godot Linux release portability strategy.
  - Rustdoc/Godotdoc API update requirement is not applicable for this workplan because this repo change is shell automation + PKGBUILD packaging metadata (no Rust source/public API changes).
