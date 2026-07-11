#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/lib.sh"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

IMAGE="${GDOPS_DOCKER_IMAGE:-godot-double-ci:latest}"
DOCKERFILE="$ROOT_DIR/docker/Dockerfile"
DOCKER_START_TIMEOUT="${GDOPS_DOCKER_START_TIMEOUT:-120}"
DOCKER_START_INTERVAL="${GDOPS_DOCKER_START_INTERVAL:-2}"

usage() {
  cat <<'USAGE'
Usage: gdops docker [--dry-run] <command> [args]

Commands:
  build                  Build the validation container image
  test                   Run gdops test inside the container
  stage <ver> <rel>      Run gdops stage inside the container
  stage latest           Stage the latest Arch godot/godot-mono version
  validate <ver> <rel>   Run gdops validate inside the container
  validate latest        Validate the latest Arch godot/godot-mono version
  ci <ver> <rel>         Run gdops ci inside the container
  ci latest              Run CI for the latest Arch godot/godot-mono version
  shell                  Open a shell inside the validation container

Environment:
  GDOPS_DOCKER_IMAGE     Image tag to build/run (default: godot-double-ci:latest)
  GDOPS_DOCKER_NO_BUILD  Set to 1 to skip the automatic build before run
  GDOPS_DOCKER_AUTO_START
                          Set to 0 to disable automatic daemon startup
  GDOPS_DOCKER_START_CMD Custom command used to start Docker
  GDOPS_DOCKER_START_TIMEOUT
                          Seconds to wait for Docker readiness (default: 120)
USAGE
}

docker_ready() {
  docker info >/dev/null 2>&1
}

wait_for_docker() {
  local deadline

  [[ "$DOCKER_START_TIMEOUT" =~ ^[0-9]+$ ]] || die "GDOPS_DOCKER_START_TIMEOUT must be an integer"
  [[ "$DOCKER_START_INTERVAL" =~ ^[0-9]+$ ]] || die "GDOPS_DOCKER_START_INTERVAL must be an integer"

  deadline=$((SECONDS + DOCKER_START_TIMEOUT))
  until docker_ready; do
    if (( SECONDS >= deadline )); then
      die "Docker daemon did not become ready within ${DOCKER_START_TIMEOUT}s"
    fi
    sleep "$DOCKER_START_INTERVAL"
  done
}

start_docker() {
  if [[ -n "${GDOPS_DOCKER_START_CMD:-}" ]]; then
    log "Starting Docker with GDOPS_DOCKER_START_CMD"
    run_cmd_str "$GDOPS_DOCKER_START_CMD"
    return 0
  fi

  if command -v systemctl >/dev/null 2>&1 &&
    systemctl --user list-unit-files docker-desktop.service >/dev/null 2>&1; then
    log "Starting Docker Desktop user service"
    run_cmd systemctl --user start docker-desktop.service
    return 0
  fi

  if docker desktop --help >/dev/null 2>&1; then
    log "Starting Docker Desktop"
    run_cmd docker desktop start
    return 0
  fi

  if command -v systemctl >/dev/null 2>&1 &&
    systemctl list-unit-files docker.service >/dev/null 2>&1; then
    if [[ "$(id -u)" -eq 0 ]]; then
      log "Starting system Docker service"
      run_cmd systemctl start docker.service
      return 0
    fi
    if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
      log "Starting system Docker service with sudo"
      run_cmd sudo -n systemctl start docker.service
      return 0
    fi
  fi

  die "Docker daemon is not running and no noninteractive start method was found"
}

ensure_docker_ready() {
  require_cmd docker
  if docker_ready; then
    return 0
  fi

  if [[ "${GDOPS_DOCKER_AUTO_START:-1}" == "0" ]]; then
    die "Docker daemon is not running"
  fi

  log "Docker daemon is not reachable; attempting to start it"
  start_docker
  wait_for_docker
}

docker_build() {
  if [[ "$DRY_RUN" -eq 0 ]]; then
    ensure_docker_ready
  fi
  run_cmd docker build -f "$DOCKERFILE" -t "$IMAGE" "$ROOT_DIR"
}

docker_run() {
  local interactive=()
  local docker_env=()
  local passthrough_var
  if [[ "${1:-}" == "--interactive" ]]; then
    interactive=(--interactive)
    shift
    if [[ -t 0 && -t 1 ]]; then
      interactive+=(--tty)
    fi
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    ensure_docker_ready
    run_cmd mkdir -p "$DIST_DIR"
  fi

  docker_env=(
    -e "LOCAL_UID=$(id -u)"
    -e "LOCAL_GID=$(id -g)"
  )
  for passthrough_var in GDOPS_SCONS_JOBS MAKEPKG_ARGS; do
    if [[ -n "${!passthrough_var+x}" ]]; then
      docker_env+=(-e "$passthrough_var=${!passthrough_var}")
    fi
  done

  run_cmd docker run --rm "${interactive[@]}" \
    "${docker_env[@]}" \
    -v "$ROOT_DIR:/workspace" \
    -w /workspace \
    "$IMAGE" "$@"
}

cmd="${1:-}"
case "$cmd" in
  -h|--help|help|"")
    usage
    exit 0
    ;;
esac
shift

case "$cmd" in
  build)
    if [[ $# -gt 0 ]]; then
      usage
      exit 1
    fi
    docker_build
    ;;
  validate)
    if [[ "${1:-}" != "--dry-run" && "${1:-}" != "latest" ]]; then
      if [[ $# -lt 2 ]]; then
        usage
        exit 1
      fi
      validate_bump_args "$1" "$2"
    fi
    if [[ "${GDOPS_DOCKER_NO_BUILD:-0}" -ne 1 ]]; then
      docker_build
    fi
    docker_run ./bin/gdops validate "$@"
    ;;
  stage)
    if [[ "${1:-}" != "--dry-run" && "${1:-}" != "latest" ]]; then
      if [[ $# -lt 2 ]]; then
        usage
        exit 1
      fi
      validate_bump_args "$1" "$2"
    fi
    if [[ "${GDOPS_DOCKER_NO_BUILD:-0}" -ne 1 ]]; then
      docker_build
    fi
    docker_run ./bin/gdops stage "$@"
    ;;
  test)
    if [[ $# -gt 0 ]]; then
      usage
      exit 1
    fi
    if [[ "${GDOPS_DOCKER_NO_BUILD:-0}" -ne 1 ]]; then
      docker_build
    fi
    docker_run ./bin/gdops test
    ;;
  ci)
    if [[ "${1:-}" != "--dry-run" && "${1:-}" != "latest" ]]; then
      if [[ $# -lt 2 ]]; then
        usage
        exit 1
      fi
      validate_bump_args "$1" "$2"
    fi
    if [[ "${GDOPS_DOCKER_NO_BUILD:-0}" -ne 1 ]]; then
      docker_build
    fi
    docker_run ./bin/gdops ci "$@"
    ;;
  shell)
    if [[ $# -gt 0 ]]; then
      usage
      exit 1
    fi
    if [[ "${GDOPS_DOCKER_NO_BUILD:-0}" -ne 1 ]]; then
      docker_build
    fi
    docker_run --interactive /bin/bash
    ;;
  *)
    printf 'Unknown docker command: %s\n\n' "$cmd" >&2
    usage
    exit 1
    ;;
esac
