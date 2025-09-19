#!/usr/bin/env zsh
# Lazy completion setup for stowx helper CLI.

# Marker for verification
typeset -g STOWX_COMPLETION_READY=1

# Skip if stowx is unavailable
if (( ! $+commands[stowx] )); then
  return 0
fi

# Preserve any existing after-compinit hook
if typeset -f __ami_after_compinit >/dev/null; then
  functions -c __ami_after_compinit __ami_after_compinit_stowx_prev 2>/dev/null || true
fi

__ami_stowx_register_completion() {
  emulate -L zsh

  [[ -n ${__AMI_STOWX_COMPLETION_DONE:-} ]] && return 0

  _stowx_resolve_dir() {
    local dir=${STOW_DIR:-"$HOME/_env/stow"}
    local idx next
    for (( idx = 1; idx < ${#words[@]} + 1; ++idx )); do
      case ${words[idx]} in
        -d|--dir)
          next=${words[idx+1]-}
          [[ -n $next ]] && dir=$next
          ;;
      esac
    done
    dir=${dir/#\~/$HOME}
    print -r -- "$dir"
  }

  _stowx_after_double_dash() {
    local idx
    for (( idx = 1; idx < CURRENT; ++idx )); do
      [[ ${words[idx]} == -- ]] && return 0
    done
    return 1
  }

  _stowx_complete_packages() {
    local dir=$(_stowx_resolve_dir)
    [[ -d $dir ]] || return 1
    local path
    local -a pkgs=()
    for path in "$dir"/*(/N); do
      pkgs+=("${path:t}")
    done
    (( ${#pkgs[@]} )) || return 1
    _wanted stowx-packages expl 'stowx package' compadd -a pkgs
  }

  _stowx_detect_command() {
    local word
    for word in ${words[@]:1}; do
      case $word in
        --) return 1 ;;
        preview|apply|adopt|grab|unstow|restow|list|help)
          print -r -- "$word"
          return 0
          ;;
        -*) ;;
        *)
          # treat first bare word as command candidate
          print -r -- "$word"
          return 0
          ;;
      esac
    done
    return 1
  }

  _stowx_complete_grab_paths() {
    _files
  }

  _stowx() {
    local curcontext="$curcontext" state
    typeset -a _global_opts
    _global_opts=(
      '(-h --help)'{-h,--help}'[show help message]'
      '(-d --dir)'{-d,--dir}'[set stow root directory]:stow directory:_files -/'
      '(-t --target)'{-t,--target}'[set target directory]:target directory:_files -/'
      '(-C --relative-to-cwd)'{-C,--relative-to-cwd}'[treat grab paths as relative to current directory]'
      '(-n --dry-run)'{-n,--dry-run}'[enable dry-run for stow operations]'
      '(-v --verbose)'{-v,--verbose}'[enable verbose output]'
      '(-p --package)'{-p,--package}'[select package (repeatable)]:package name:->package'
      '(-y --yes)'{-y,--yes}'[assume yes for confirmations]'
      '(-r --restore)'{-r,--restore}'[after adopt, restore tracked files]'
      '(--no-restore)--no-restore[skip restore step after adopt]'
    )

    local -a _commands=(
      'preview:预览 stow 将执行的变更'
      'apply:应用链接到目标目录'
      'adopt:收编现有文件（可选 --restore 覆盖）'
      'grab:抓取文件/目录到指定包'
      'unstow:移除已建立的链接'
      'restow:重新建立链接'
      'list:列出 STOW_DIR 中的包'
      'help:显示帮助信息'
    )

    _arguments -s -S -C \
      ${_global_opts[@]} \
      '1:command:->command' \
      '*::arg:->args' && return 0

    case $state in
      command)
        _describe -t stowx-commands 'stowx commands' _commands
        return 0
        ;;
      package)
        _stowx_complete_packages
        return 0
        ;;
      args)
        if ! _stowx_after_double_dash; then
          local cmd
          cmd=$(_stowx_detect_command 2>/dev/null)
          case ${cmd:-} in
            preview|apply|adopt|unstow|restow)
              _stowx_complete_packages && return 0
              ;;
            list|help|'')
              _message 'no additional arguments'
              return 0
              ;;
            grab)
              _stowx_complete_grab_paths
              return 0
              ;;
          esac
        fi
        _normal
        ;;
    esac
  }

  compdef _stowx stowx
  __AMI_STOWX_COMPLETION_DONE=1
}

__ami_after_compinit() {
  if typeset -f __ami_after_compinit_stowx_prev >/dev/null; then
    __ami_after_compinit_stowx_prev "$@"
  fi
  __ami_stowx_register_completion
}
