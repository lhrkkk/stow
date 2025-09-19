#!/usr/bin/env zsh
# Lazy completion setup for report-kit CLI.

# Expose marker for quick verification
typeset -g REPORT_KIT_COMPLETION_READY=1

# Skip if report-kit is missing
if (( ! $+commands[report-kit] )); then
  return 0
fi

# Chain existing after-compinit hook if present
if typeset -f __ami_after_compinit >/dev/null; then
  functions -c __ami_after_compinit __ami_after_compinit_report_kit_prev 2>/dev/null || true
fi

__ami_report_kit_register_completion() {
  emulate -L zsh

  # Only register once per shell
  [[ -n ${__AMI_REPORT_KIT_COMPLETION_DONE:-} ]] && return 0

  local _script
  _script=$(report-kit completion zsh --fallback 2>/dev/null) || return 0

  eval "${_script}" || return 0

  if ! typeset -f __ami_report_kit_alias_proxy >/dev/null 2>&1; then
    __ami_report_kit_alias_proxy() {
      emulate -L zsh
      local -a _rk_words_copy
      _rk_words_copy=("${words[@]}")
      words[1]=report-kit
      _shtab_report_kit "$@"
      words=("${_rk_words_copy[@]}")
    }
  fi

  local _rk_alias
  for _rk_alias in ${(k)aliases}; do
    if [[ ${aliases[$_rk_alias]} == report-kit* ]]; then
      compdef __ami_report_kit_alias_proxy $_rk_alias
    fi
  done
  __AMI_REPORT_KIT_COMPLETION_DONE=1
}

__ami_after_compinit() {
  if typeset -f __ami_after_compinit_report_kit_prev >/dev/null; then
    __ami_after_compinit_report_kit_prev "$@"
  fi
  __ami_report_kit_register_completion
}
