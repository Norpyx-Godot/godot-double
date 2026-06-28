---
status: done
priority: P1
owner: "codex"
updated: 2026-06-28
---

# Idle Update Checker And Notifier

## Goal
- Add a host-side scheduled update checker that only runs the expensive Docker update while the machine is idle, then shows a persistent notification when artifacts are ready to release.

## Scope
### In
- A version check command comparing local `godot-double` and `godot-double-bin` versions against official Arch `godot` / `godot-mono`.
- An idle-gated update runner with locking, logs, and persistent desktop notification.
- A systemd user timer installer.
- Tests and docs for the new commands.

### Out
- Running release/commit/push automatically.
- Requiring host package build dependencies for Docker update.
- Generating or installing SSH keys automatically.

## Acceptance Criteria
- `./bin/gdops check-update` reports whether an update is needed.
- `./bin/gdops idle-update` exits without building unless the idle threshold is met and an update is needed.
- `./bin/gdops install-idle-timer` installs a user-level systemd timer that periodically invokes the idle checker.
- Success and failure notifications are persistent when `notify-send` is available.
- Tests and coverage pass.

## Plan
### Step 1
- Do: Add a read-only update checker that compares local source/bin PKGBUILD versions with official Arch `godot` and `godot-mono`.
- Verify: Stub `pacman -Si` responses in shell tests for current, newer, and binary-drift cases.
- Docs: Document `gdops check-update`.
- Coverage impact: Add checker to coverage gate.

### Step 2
- Do: Add an idle-gated runner with locking, logs, dry-run support, and persistent notifications.
- Verify: Stub idle detectors and `pacman` responses in shell tests.
- Docs: Document idle threshold, logs, and notification behavior.
- Coverage impact: Add scheduler to coverage gate.

### Step 3
- Do: Add a user systemd timer installer.
- Verify: Dry-run the generated unit output and install into a temp config directory with stubbed `systemctl`.
- Docs: Document installation command and host optional tools.
- Coverage impact: Add installer to coverage gate.

## Decisions
- 2026-06-28:
  - Use a systemd user timer instead of cron because this is a desktop-idle workflow with logs and environment requirements.
  - Default idle threshold is 7200 seconds.
  - No SSH key is required for `update`; release/push credentials remain a separate concern.
  - Do not automatically enable the timer during implementation; provide `gdops install-idle-timer` so the maintainer controls when scheduling begins.

## Verification
- 2026-06-28:
  - `bash -n bin/gdops scripts/*.sh tests/*.sh docker/entrypoint.sh`
  - `./tests/run.sh`
  - `./tests/coverage.sh` (`line_coverage 523/637 82.1%`)
  - `docker run --rm godot-double-ci:latest ... pacman -Sp ...` resolved the reported missing dependencies inside the container.
