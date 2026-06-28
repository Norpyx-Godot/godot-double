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
USAGE
}

docker_build() {
  if [[ "$DRY_RUN" -eq 0 ]]; then
    require_cmd docker
  fi
  run_cmd docker build -f "$DOCKERFILE" -t "$IMAGE" "$ROOT_DIR"
}

docker_run() {
  local interactive=()
  if [[ "${1:-}" == "--interactive" ]]; then
    interactive=(--interactive)
    shift
    if [[ -t 0 && -t 1 ]]; then
      interactive+=(--tty)
    fi
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    require_cmd docker
    run_cmd mkdir -p "$DIST_DIR"
  fi

  run_cmd docker run --rm "${interactive[@]}" \
    -e "LOCAL_UID=$(id -u)" \
    -e "LOCAL_GID=$(id -g)" \
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
