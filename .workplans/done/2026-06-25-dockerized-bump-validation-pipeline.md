---
status: done
priority: P1
owner: "codex"
updated: 2026-06-25
---

# Dockerized Bump Validation Pipeline

## Goal
- Make a proposed `godot-double` version bump pass or fail through repeatable Docker stages before release promotion.

## Scope
### In
- Dockerized, provider-neutral validation entrypoints for local and CI use.
- Stage commands for preflight, bump validation, source metadata validation, package build validation, and binary package hydration validation.
- Documentation for running the validation pipeline and interpreting pass/fail behavior.
- Focused tests for shell stage behavior that can run without building Godot.

### Out
- Automatic GitHub release publishing.
- Automatic AUR pushes.
- Full Mono portability validation.
- Solving older-glibc runtime portability; that remains covered by the existing portable-runtime workplan.

## Acceptance Criteria
- `./bin/gdops validate <pkgver> <pkgrel>` runs a local pass/fail validation sequence without publishing, committing, or pushing.
- A Docker entrypoint runs the same validation sequence inside a reusable Arch-based container.
- CI runners can call the Docker validation command without knowing the internal script sequence.
- Validation fails on invalid version input, missing submodules, missing package metadata, `.SRCINFO` drift, missing artifacts after build, or failed binary hydration.
- Existing commands (`bump`, `pull`, `build`, `hydrate`, `release`, `commit`, `push`, `all`) remain available.
- README documents local validation, Docker validation, and CI usage.

## Notes / Context
- Current release flow is split across `bin/gdops` and scripts in `scripts/`.
- `godot-double` and `godot-double-bin` are AUR submodules on `master`.
- The repository currently has an uncommitted bump in `godot-double` from `4.6-1` to `4.6.3-0`.
- There is no existing GitHub Actions workflow; the first pass should be Docker-first and provider-neutral.
- `dist/` is ignored and is the appropriate host-visible artifact location.

## Plan (steps)
### Step 1
- Do: Add this in-progress workplan and keep existing workplan folders with `.gitkeep`.
- Verify: Confirm workplan file exists under `.workplans/in-progress/`.
- Docs: None.
- Coverage impact: None.

### Step 2
- Do: Add shared validation helpers and stage scripts for preflight, bump, source metadata, artifact, and hydration checks.
- Verify: Run stage commands in dry-run or fixture mode where possible.
- Docs: Inline command usage in scripts.
- Coverage impact: Add shell tests for failure modes that do not require a full Godot build.

### Step 3
- Do: Add Docker image/run wrappers that execute validation in an Arch-based container with repo and `dist/` mounted.
- Verify: Run Docker dry-run/help path if Docker is available.
- Docs: Document local Docker and CI invocation.
- Coverage impact: Test wrapper command construction where practical.

### Step 4
- Do: Wire new commands through `bin/gdops` while preserving existing command behavior.
- Verify: Run `./bin/gdops --help`, `./bin/gdops validate --dry-run <pkgver> <pkgrel>`, and existing dry-run flow.
- Docs: Update README command list and examples.
- Coverage impact: Add command-dispatch tests where practical.

### Step 5
- Do: Add lightweight shell test runner and tests.
- Verify: Run tests locally.
- Docs: Record canonical test/coverage/docs commands in README.
- Coverage impact: Shell tests provide coverage for validation command behavior; formal line/branch coverage remains a follow-up unless shell coverage tooling is added.

## Open Questions
- Should a follow-up add a GitHub Actions workflow that calls the Dockerized validation command?
- Should full runtime audits become part of the default bump gate after the portable-runtime workplan lands?

## Decisions
- 2026-06-25:
  - Docker is the first-class execution environment for CI readiness.
  - The first pipeline validates and builds the non-Mono package path enough to hydrate `godot-double-bin`, but does not publish.
  - Promotion stays explicit and separate from validation.
  - Runtime portability audits are integration points, not mandatory for this first implementation.
  - Line coverage for the new validation surface is enforced with a Bash xtrace coverage gate at 80% or higher. Branch coverage is explicitly excluded for this shell-only change because the repo has no reliable branch coverage harness for Bash; compensation is targeted tests for success, failure, help, dry-run, and stubbed non-dry validation paths.

## Verification
- 2026-06-25:
  - `./tests/run.sh` passed.
  - `./tests/coverage.sh` passed with line coverage `259/302` (`85.8%`) for the new validation surface.
  - `./bin/gdops --dry-run ci 4.6.3 0` passed.
  - `./bin/gdops all --dry-run 4.6.3 0` passed.
  - `./bin/gdops docker build` passed.
  - `GDOPS_DOCKER_NO_BUILD=1 ./bin/gdops docker ci --dry-run 4.6.3 0` passed.
  - Containerized `./tests/coverage.sh` passed with the same `85.8%` line coverage.
