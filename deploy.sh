#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$SCRIPT_DIR"

DEFAULT_REMOTE="lhr@43.137.38.19"
DEFAULT_PORT="6000"
DEFAULT_REMOTE_DIR="/SDA/lhr/_env/stow"

COMMAND="deploy"
REMOTE="${DEPLOY_REMOTE:-$DEFAULT_REMOTE}"
REMOTE_PORT="${DEPLOY_PORT:-$DEFAULT_PORT}"
REMOTE_DIR="${DEPLOY_REMOTE_DIR:-$DEFAULT_REMOTE_DIR}"
WITH_BREW=0
DELETE_REMOTE=1
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  deploy.sh [deploy|update|apply] [options]

Commands:
  deploy, update  Rsync local repo to remote, then run remote bootstrap update
  apply           Rsync local repo to remote, then run remote bootstrap apply

Options:
      --remote <user@host>   Remote SSH target
      --port <port>          Remote SSH port
      --remote-dir <path>    Remote repo path
      --with-brew            Include remote Homebrew update/bundle steps
      --no-delete            Do not delete files on the remote that were removed locally
      --dry-run              Show rsync changes but do not modify the remote
      --host[=NAME]          Pass through to remote bootstrap.sh
      --no-host              Pass through to remote bootstrap.sh
      --skip-pull            Pass through to remote bootstrap.sh update
      --allow-dirty          Pass through to remote bootstrap.sh update
  -h, --help                 Show this help

Defaults:
  remote      lhr@43.137.38.19
  port        6000
  remote-dir  /SDA/lhr/_env/stow

Examples:
  ./deploy.sh
  ./deploy.sh --with-brew
  ./deploy.sh --remote lhr@example.com --port 22 --remote-dir ~/stow
  ./deploy.sh apply --host
EOF
}

run() {
  printf '[deploy] + %s\n' "$*"
  "$@"
}

quote_cmd() {
  local out=""
  local arg
  for arg in "$@"; do
    printf -v arg '%q' "$arg"
    out+=" $arg"
  done
  printf '%s\n' "${out# }"
}

parse_args() {
  PASSTHRU_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      deploy|update|apply)
        COMMAND="$1"
        shift
        ;;
      --remote)
        [[ $# -ge 2 ]] || { printf '[deploy][ERR] --remote requires a value\n' >&2; exit 1; }
        REMOTE="$2"
        shift 2
        ;;
      --port)
        [[ $# -ge 2 ]] || { printf '[deploy][ERR] --port requires a value\n' >&2; exit 1; }
        REMOTE_PORT="$2"
        shift 2
        ;;
      --remote-dir)
        [[ $# -ge 2 ]] || { printf '[deploy][ERR] --remote-dir requires a value\n' >&2; exit 1; }
        REMOTE_DIR="$2"
        shift 2
        ;;
      --with-brew)
        WITH_BREW=1
        shift
        ;;
      --no-delete)
        DELETE_REMOTE=0
        shift
        ;;
      --dry-run)
        DRY_RUN=1
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

sync_remote() {
  local -a ssh_cmd=(ssh -p "$REMOTE_PORT")
  local -a rsync_cmd=(
    rsync -az
    --exclude .git/
    --exclude .jj/
    --exclude .DS_Store
    --exclude '*.zwc'
    --exclude .aider/
    --exclude .claude/
    --exclude .specstory/
    --exclude .cursor/
  )

  if [[ $DELETE_REMOTE -eq 1 ]]; then
    rsync_cmd+=(--delete)
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    rsync_cmd+=(--dry-run)
  fi

  run "${ssh_cmd[@]}" "$REMOTE" "mkdir -p $(printf '%q' "$REMOTE_DIR")"
  run "${rsync_cmd[@]}" -e "ssh -p $REMOTE_PORT" "$REPO_ROOT/" "$REMOTE:$REMOTE_DIR/"
}

run_remote_bootstrap() {
  local -a remote_cmd=(./bootstrap.sh)

  case "$COMMAND" in
    deploy|update)
      remote_cmd+=(update --skip-pull)
      ;;
    apply)
      remote_cmd+=(bootstrap)
      ;;
    *)
      printf '[deploy][ERR] unknown command: %s\n' "$COMMAND" >&2
      exit 1
      ;;
  esac

  if [[ $WITH_BREW -eq 0 ]]; then
    remote_cmd+=(--skip-brew)
  fi
  remote_cmd+=("${PASSTHRU_ARGS[@]}")

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[deploy] dry-run remote command: cd %s && chmod +x bootstrap.sh deploy.sh && %s\n' \
      "$REMOTE_DIR" "$(quote_cmd "${remote_cmd[@]}")"
    return 0
  fi

  run ssh -p "$REMOTE_PORT" "$REMOTE" \
    "cd $(printf '%q' "$REMOTE_DIR") && chmod +x bootstrap.sh deploy.sh && $(quote_cmd "${remote_cmd[@]}")"
}

main() {
  parse_args "$@"
  sync_remote
  run_remote_bootstrap
}

main "$@"
