---
status: done
priority: P1
owner: "codex"
updated: 2026-07-10
---

# Auto Start Docker

## Goal
- Make Docker-backed `gdops` commands start Docker automatically when the CLI exists but the daemon/API is not reachable.

## Scope
### In
- Detect daemon readiness with `docker info`.
- Start Docker Desktop through a user systemd service when available.
- Support a custom start command for other host setups.
- Wait for the daemon to become ready before `docker build` or `docker run`.
- Tests and docs.

### Out
- Installing Docker.
- Blocking interactive sudo prompts.
- Changing container build behavior after Docker is ready.

## Acceptance Criteria
- `gdops docker build` attempts to start Docker when `docker info` fails.
- Startup is bounded by a configurable timeout.
- Dry-run behavior still does not require Docker.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Add daemon readiness, auto-start, and wait helpers to `scripts/docker.sh`.
- Verify: Stub `docker` and `systemctl` in tests.
- Docs: Document auto-start environment variables.
- Coverage impact: Existing Docker tests plus new auto-start test cover the branch.

## Decisions
- 2026-07-10:
  - Default auto-start is enabled.
  - Prefer `systemctl --user start docker-desktop.service` for Docker Desktop.
  - Avoid interactive sudo; only use `sudo -n` for system Docker if already permitted.

## Verification
- 2026-07-10:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 640/795 80.5%`)
  - `./bin/gdops --dry-run docker build` still avoids requiring Docker.
