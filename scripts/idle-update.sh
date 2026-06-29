#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

usage() {
  cat <<'USAGE'
Usage: gdops idle-update [--dry-run]

Checks whether the official Arch godot/godot-mono package version is newer than
the local godot-double packages. If an update is needed and the machine has been
idle long enough, runs the Dockerized update flow and sends a persistent desktop
notification.

Environment:
  GDOPS_IDLE_SECONDS       Required idle time in seconds (default: 7200)
  GDOPS_IDLE_IGNORE=1      Skip idle detection, useful for manual runs/tests
  GDOPS_UPDATE_LOG_DIR     Directory for update logs (default: dist/idle-update-logs)
  GDOPS_IDLE_LOCK_FILE     Lock file path (default: dist/idle-update.lock)
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

if [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

IDLE_THRESHOLD="${GDOPS_IDLE_SECONDS:-7200}"
LOG_DIR="${GDOPS_UPDATE_LOG_DIR:-$DIST_DIR/idle-update-logs}"
LOCK_FILE="${GDOPS_IDLE_LOCK_FILE:-$DIST_DIR/idle-update.lock}"

[[ "$IDLE_THRESHOLD" =~ ^[0-9]+$ ]] || die "GDOPS_IDLE_SECONDS must be an integer"

notify_desktop() {
  local urgency="$1"
  local summary="$2"
  local body="$3"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] notify-send -u %q -t 0 %q %q\n' "$urgency" "$summary" "$body"
    return 0
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -t 0 "$summary" "$body" || true
  else
    printf 'notification[%s]: %s: %s\n' "$urgency" "$summary" "$body"
  fi
}

idle_seconds_from_xprintidle() {
  local idle_ms

  command -v xprintidle >/dev/null 2>&1 || return 1
  idle_ms="$(xprintidle 2>/dev/null || true)"
  [[ "$idle_ms" =~ ^[0-9]+$ ]] || return 1
  printf '%d\n' "$((idle_ms / 1000))"
}

idle_seconds_from_loginctl() {
  local props idle_hint idle_since_usec now

  command -v loginctl >/dev/null 2>&1 || return 1
  [[ -n "${XDG_SESSION_ID:-}" ]] || return 1

  props="$(loginctl show-session "$XDG_SESSION_ID" -p IdleHint -p IdleSinceHint 2>/dev/null || true)"
  [[ -n "$props" ]] || return 1

  idle_since_usec="$(awk -F= '$1 == "IdleSinceHint" { print $2 }' <<<"$props")"
  if [[ "$idle_since_usec" =~ ^[0-9]+$ && "$idle_since_usec" -gt 0 ]]; then
    now="$(date +%s)"
    printf '%d\n' "$((now - idle_since_usec / 1000000))"
    return 0
  fi

  idle_hint="$(awk -F= '$1 == "IdleHint" { print $2 }' <<<"$props")"
  if [[ "$idle_hint" == "yes" ]]; then
    printf '%s\n' "$IDLE_THRESHOLD"
    return 0
  fi
  if [[ "$idle_hint" == "no" ]]; then
    printf '0\n'
    return 0
  fi

  return 1
}

current_idle_seconds() {
  if [[ "${GDOPS_IDLE_IGNORE:-0}" == "1" ]]; then
    printf '%s\n' "$IDLE_THRESHOLD"
    return 0
  fi

  idle_seconds_from_xprintidle && return 0
  idle_seconds_from_loginctl && return 0
  return 1
}

if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$LOG_DIR"
  mkdir -p "$(dirname "$LOCK_FILE")"
  if command -v flock >/dev/null 2>&1; then
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
      log "another idle update check is already running"
      exit 0
    fi
  fi
fi

if ! idle_seconds="$(current_idle_seconds)"; then
  log "could not determine desktop idle time; install xprintidle or set GDOPS_IDLE_IGNORE=1"
  exit 0
fi

if (( idle_seconds < IDLE_THRESHOLD )); then
  log "idle_seconds=$idle_seconds threshold=$IDLE_THRESHOLD; skipping update check"
  exit 0
fi

log "idle_seconds=$idle_seconds threshold=$IDLE_THRESHOLD; checking for update"

set +e
check_output="$("$SCRIPT_DIR/check-update.sh" --exit-code 2>&1)"
check_status=$?
set -e

printf '%s\n' "$check_output"

case "$check_status" in
  0)
    log "update needed; running Dockerized update flow"
    ;;
  1)
    log "local packages match official Arch package version"
    exit 0
    ;;
  *)
    notify_desktop critical "godot-double update check failed" "$check_output"
    exit "$check_status"
    ;;
esac

if [[ "$DRY_RUN" -eq 1 ]]; then
  run_cmd "$ROOT_DIR/bin/gdops" update
  notify_desktop critical "godot-double update staged" "Dry run: update would run. Review, then release/commit/push."
  exit 0
fi

log_file="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"
if "$ROOT_DIR/bin/gdops" update >"$log_file" 2>&1; then
  notify_desktop critical "godot-double update staged" "Artifacts are ready. Review, then run: ./bin/gdops release; ./bin/gdops commit; ./bin/gdops push"
  log "update completed; log=$log_file"
else
  status=$?
  notify_desktop critical "godot-double update failed" "Update failed with exit $status. See $log_file"
  tail -n 40 "$log_file" >&2 || true
  exit "$status"
fi
