#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$SCRIPT_DIR"
BOOTSTRAP="$REPO_ROOT/bootstrap.sh"

COMMAND="deploy"
WITH_BREW=0

usage() {
  cat <<'EOF'
Usage:
  deploy.sh [deploy|update|apply] [options]

Commands:
  deploy, update  Pull latest changes and restow links (default)
  apply           Apply links without pulling

Options:
      --with-brew   Include Homebrew update/bundle steps
      --host[=NAME] Pass through to bootstrap.sh
      --no-host     Pass through to bootstrap.sh
      --skip-pull   Pass through to bootstrap.sh update
      --allow-dirty Pass through to bootstrap.sh update
  -h, --help        Show this help

Examples:
  ./deploy.sh
  ./deploy.sh --with-brew
  ./deploy.sh apply
  ./deploy.sh update --allow-dirty
EOF
}

parse_args() {
  PASSTHRU_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      deploy|update|apply)
        COMMAND="$1"
        shift
        ;;
      --with-brew)
        WITH_BREW=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        PASSTHRU_ARGS+=("$1")
        shift
        ;;
    esac
  done
}

run() {
  printf '[deploy] + %s\n' "$*"
  "$@"
}

main() {
  parse_args "$@"
  [[ -x "$BOOTSTRAP" ]] || {
    printf '[deploy][ERR] missing bootstrap script: %s\n' "$BOOTSTRAP" >&2
    exit 1
  }

  case "$COMMAND" in
    deploy|update)
      if [[ $WITH_BREW -eq 1 ]]; then
        run "$BOOTSTRAP" update "${PASSTHRU_ARGS[@]}"
      else
        run "$BOOTSTRAP" update --skip-brew "${PASSTHRU_ARGS[@]}"
      fi
      ;;
    apply)
      if [[ $WITH_BREW -eq 1 ]]; then
        run "$BOOTSTRAP" bootstrap "${PASSTHRU_ARGS[@]}"
      else
        run "$BOOTSTRAP" bootstrap --skip-brew "${PASSTHRU_ARGS[@]}"
      fi
      ;;
    *)
      printf '[deploy][ERR] unknown command: %s\n' "$COMMAND" >&2
      exit 1
      ;;
  esac
}

main "$@"
