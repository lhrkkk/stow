#!/usr/bin/env zsh
# Lazy completion setup for report-kit CLI.

# Expose marker for quick verification
typeset -g REPORT_KIT_COMPLETION_READY=1

# Skip if report-kit is missing
if (( ! $+commands[report-kit] )); then
  return 0
fi

# Hold previous after-compinit hook if it exists so we can chain
if typeset -f __ami_after_compinit >/dev/null; then
  functions -c __ami_after_compinit __ami_after_compinit_report_kit_prev 2>/dev/null || true
fi

__ami_report_kit_register_completion() {
  emulate -L zsh
  setopt localoptions
  unsetopt xtrace verbose

  # Only register once per shell
  [[ -n ${__AMI_REPORT_KIT_COMPLETION_DONE:-} ]] && return 0

  local _script
  _script=$(report-kit completion zsh --fallback 2>/dev/null) || return 0
  eval "${_script}" || return 0

  (( ${+__AMI_REPORT_KIT_ALIAS_DONE} )) || typeset -gA __AMI_REPORT_KIT_ALIAS_DONE

  local _rk_alias _rk_alias_script
  for _rk_alias in ${(k)aliases}; do
    if [[ ${aliases[$_rk_alias]} == report-kit* && $_rk_alias != report-kit ]]; then
      [[ -n ${__AMI_REPORT_KIT_ALIAS_DONE[$_rk_alias]:-} ]] && continue
      _rk_alias_script=$(report-kit completion zsh --fallback --prog "$_rk_alias" 2>/dev/null) || continue
      eval "${_rk_alias_script}" || continue
      __AMI_REPORT_KIT_ALIAS_DONE[$_rk_alias]=1
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
