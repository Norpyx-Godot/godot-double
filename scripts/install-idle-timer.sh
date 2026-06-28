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
Usage: gdops install-idle-timer [--dry-run]

Installs and enables a user-level systemd timer that periodically invokes
`gdops idle-update`. The command is host-side; the update/build itself still
runs through the Dockerized gdops update flow.

Environment:
  GDOPS_IDLE_SECONDS          Idle threshold written into the service (default: 7200)
  GDOPS_IDLE_TIMER_INTERVAL   Timer interval (default: 30min)
  GDOPS_IDLE_TIMER_BOOT_DELAY Initial delay after boot/login (default: 30min)
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
TIMER_INTERVAL="${GDOPS_IDLE_TIMER_INTERVAL:-30min}"
BOOT_DELAY="${GDOPS_IDLE_TIMER_BOOT_DELAY:-30min}"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_NAME="gdops-idle-update.service"
TIMER_NAME="gdops-idle-update.timer"
SERVICE_PATH="$UNIT_DIR/$SERVICE_NAME"
TIMER_PATH="$UNIT_DIR/$TIMER_NAME"

[[ "$IDLE_THRESHOLD" =~ ^[0-9]+$ ]] || die "GDOPS_IDLE_SECONDS must be an integer"

write_service() {
  cat <<EOF
[Unit]
Description=godot-double idle update check

[Service]
Type=oneshot
WorkingDirectory=$ROOT_DIR
Environment=GDOPS_IDLE_SECONDS=$IDLE_THRESHOLD
ExecStart=$ROOT_DIR/bin/gdops idle-update
EOF
}

write_timer() {
  cat <<EOF
[Unit]
Description=Run godot-double idle update check periodically

[Timer]
OnBootSec=$BOOT_DELAY
OnUnitActiveSec=$TIMER_INTERVAL
AccuracySec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '[dry-run] write %s\n' "$SERVICE_PATH"
  write_service
  printf '\n[dry-run] write %s\n' "$TIMER_PATH"
  write_timer
  printf '\n'
  run_cmd systemctl --user daemon-reload
  run_cmd systemctl --user enable --now "$TIMER_NAME"
  exit 0
fi

require_cmd systemctl

mkdir -p "$UNIT_DIR"
write_service > "$SERVICE_PATH"
write_timer > "$TIMER_PATH"

systemctl --user daemon-reload
systemctl --user enable --now "$TIMER_NAME"

log "installed and enabled $TIMER_NAME"
log "service=$SERVICE_PATH"
log "timer=$TIMER_PATH"
