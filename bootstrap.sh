#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$SCRIPT_DIR"
BREWFILE=""
STOWX="$REPO_ROOT/mac-home/.local/bin/stowx"

COMMAND="bootstrap"
HOST_MODE="auto"
HOST_NAME=""
SKIP_BREW=0
SKIP_STOW=0
SKIP_PULL=0
ALLOW_DIRTY=0

log() {
  printf '[bootstrap] %s\n' "$*"
}

err() {
  printf '[bootstrap][ERR] %s\n' "$*" >&2
}

die() {
  err "$*"
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  bootstrap.sh [bootstrap|install|update] [options]

Commands:
  bootstrap, install  Install prerequisites, run Brewfile, apply stow links
  update              Pull latest repo changes, refresh Brewfile, restow links

Options:
      --host[=NAME]   Apply/restow hosts/<name>; without a name use current hostname
      --no-host       Skip host package even if hosts/<hostname> exists
      --skip-brew     Skip Homebrew/Brewfile steps
      --skip-stow     Skip stow/stowx steps
      --skip-pull     Skip git pull during update
      --allow-dirty   During update, continue if repo has local changes (pull is skipped)
  -h, --help          Show this help

Examples:
  ./bootstrap.sh
  ./bootstrap.sh bootstrap --host
  ./bootstrap.sh update
  ./bootstrap.sh update --allow-dirty --skip-brew
EOF
}

run() {
  log "+ $*"
  "$@"
}

sanitize_homebrew_env() {
  if [[ -n "${HOMEBREW_CURL_PATH:-}" && ! -x "${HOMEBREW_CURL_PATH}" ]]; then
    log "unset invalid HOMEBREW_CURL_PATH: ${HOMEBREW_CURL_PATH}"
    unset HOMEBREW_CURL_PATH
  fi
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

select_brewfile() {
  if is_macos; then
    BREWFILE="$REPO_ROOT/mac-home/Brewfile"
  elif is_linux; then
    BREWFILE="$REPO_ROOT/mac-home/Brewfile_linux"
  else
    die "unsupported platform: $(uname -s)"
  fi
}

find_brew_bin() {
  local candidate
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  for candidate in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

load_brew_env() {
  local brew_bin
  brew_bin="$(find_brew_bin)" || return 1
  eval "$("$brew_bin" shellenv)"
}

default_host() {
  local name
  if command -v hostname >/dev/null 2>&1; then
    name="$(hostname 2>/dev/null || true)"
    if [[ -n "$name" ]]; then
      printf '%s\n' "$name"
      return 0
    fi
  fi
  if command -v uname >/dev/null 2>&1; then
    name="$(uname -n 2>/dev/null || true)"
    if [[ -n "$name" ]]; then
      printf '%s\n' "$name"
      return 0
    fi
  fi
  return 1
}

resolve_host_name() {
  local name
  case "$HOST_MODE" in
    off)
      return 1
      ;;
    explicit)
      [[ -n "$HOST_NAME" ]] || die "--host requires a hostname or a detectable local hostname"
      name="$HOST_NAME"
      ;;
    auto)
      if [[ -n "$HOST_NAME" ]]; then
        name="$HOST_NAME"
      else
        name="$(default_host)" || return 1
      fi
      ;;
    *)
      die "unknown host mode: $HOST_MODE"
      ;;
  esac

  if [[ -d "$REPO_ROOT/hosts/$name" ]]; then
    printf '%s\n' "$name"
    return 0
  fi

  if [[ "$HOST_MODE" == "explicit" ]]; then
    die "host package not found: hosts/$name"
  fi
  return 1
}

ensure_repo_layout() {
  [[ -n "$BREWFILE" ]] || die "brewfile has not been selected"
  [[ -f "$BREWFILE" ]] || die "missing Brewfile: $BREWFILE"
  [[ -x "$STOWX" ]] || die "missing stowx helper: $STOWX"
}

ensure_xcode_clt() {
  is_macos || return 0
  if xcode-select -p >/dev/null 2>&1; then
    return 0
  fi
  run xcode-select --install || true
  die "Xcode Command Line Tools installation has been triggered; rerun this script after it finishes."
}

ensure_homebrew() {
  sanitize_homebrew_env
  if find_brew_bin >/dev/null 2>&1; then
    load_brew_env
    return 0
  fi
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_env || die "Homebrew installed, but brew is still not discoverable in this shell"
}

ensure_minimal_tools() {
  local -a missing=()
  command -v git >/dev/null 2>&1 || missing+=("git")
  command -v stow >/dev/null 2>&1 || missing+=("stow")
  if (( ${#missing[@]} > 0 )); then
    run brew install "${missing[@]}"
  fi
}

run_brew_bundle() {
  [[ $SKIP_BREW -eq 1 ]] && return 0
  ensure_xcode_clt
  ensure_homebrew
  ensure_minimal_tools
  run brew bundle --file "$BREWFILE"
}

repo_is_dirty() {
  [[ -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null || true)" ]]
}

update_repo() {
  [[ $SKIP_PULL -eq 1 ]] && return 0
  command -v git >/dev/null 2>&1 || die "git is required for update"
  if repo_is_dirty; then
    if [[ $ALLOW_DIRTY -eq 1 ]]; then
      log "repo has local changes; skipping git pull because --allow-dirty was set"
      return 0
    fi
    die "repo has local changes; commit/stash them or rerun with --allow-dirty to skip git pull"
  fi
  if git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    run git -C "$REPO_ROOT" pull --ff-only
  else
    log "no upstream configured for this repo; skipping git pull"
  fi
}

run_stow_action() {
  local action="$1"
  local host_name=""
  [[ $SKIP_STOW -eq 1 ]] && return 0
  command -v stow >/dev/null 2>&1 || die "stow is required for stow steps"

  run "$STOWX" "$action"

  if host_name="$(resolve_host_name)"; then
    run "$STOWX" "$action" --host "$host_name"
  else
    log "no matching host package to ${action}"
  fi
}

cmd_bootstrap() {
  ensure_repo_layout
  run_brew_bundle
  run_stow_action apply
  log "bootstrap complete"
}

cmd_update() {
  ensure_repo_layout
  if [[ $SKIP_BREW -eq 0 ]]; then
    ensure_homebrew
    ensure_minimal_tools
  fi
  update_repo
  [[ $SKIP_BREW -eq 1 ]] || run brew update
  run_brew_bundle
  run_stow_action restow
  log "update complete"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      bootstrap|install|update)
        COMMAND="$1"
        shift
        ;;
      --host)
        HOST_MODE="explicit"
        if [[ $# -ge 2 && ${2-} != -* ]]; then
          HOST_NAME="$2"
          shift 2
        else
          HOST_NAME="$(default_host || true)"
          shift
        fi
        ;;
      --host=*)
        HOST_MODE="explicit"
        HOST_NAME="${1#--host=}"
        if [[ -z "$HOST_NAME" ]]; then
          HOST_NAME="$(default_host || true)"
        fi
        shift
        ;;
      --no-host)
        HOST_MODE="off"
        HOST_NAME=""
        shift
        ;;
      --skip-brew)
        SKIP_BREW=1
        shift
        ;;
      --skip-stow)
        SKIP_STOW=1
        shift
        ;;
      --skip-pull)
        SKIP_PULL=1
        shift
        ;;
      --allow-dirty)
        ALLOW_DIRTY=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  select_brewfile
  case "$COMMAND" in
    bootstrap|install)
      cmd_bootstrap
      ;;
    update)
      cmd_update
      ;;
    *)
      die "unknown command: $COMMAND"
      ;;
  esac
}

main "$@"
