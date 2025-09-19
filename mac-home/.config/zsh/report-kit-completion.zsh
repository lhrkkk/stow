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

__ami_report_kit_transform_script() {
  emulate -L zsh
  local prog="$1"
  local script="$2"
  PYTHONIOENCODING=UTF-8 AMI_REPORT_KIT_SCRIPT="$script" python3 - "$prog" <<'PY'
import os
import re
import sys

prog = sys.argv[1]
script = os.environ.get("AMI_REPORT_KIT_SCRIPT", "")

prog_fn = prog.replace('-', '_')

# Adjust fallback guard or inject one for alias scripts
fallback_comment = 'Fallback: first TAB with empty prefix shows described subcommands'
if fallback_comment in script:
    script = re.sub(r'\[\[\s+\${words\[1\]:-}\s*==\s*report-kit', f'[[ ${{words[1]:-}} == {prog}', script)
    script = script.replace('[report-kit] completion', f'[{prog}] completion')
else:
    pattern = re.compile(rf'(^\s*_arguments\s+-C\s+-s\s+\$_shtab_{prog_fn}_options\s*$)', re.MULTILINE)
    if pattern.search(script):
        block = (
            "  # Fallback: first TAB with empty prefix shows described subcommands\n"
            f"  if [[ ${{words[1]:-}} == {prog} && $CURRENT -eq 2 && -z ${{words[CURRENT]}} ]]; then\n"
            "    if [[ -n ${REPORT_KIT_COMPLETION_DEBUG-} ]]; then\n"
            f"      print -u2 -- \"[{prog}] completion: fallback triggered (CURRENT=$CURRENT word=${{words[CURRENT]:-<empty>}})\"\n"
            "    fi\n"
            f"    _shtab_{prog_fn}_commands\n"
            "    return 0\n"
            "  fi\n"
        )
        script = pattern.sub(lambda m: block + "\n" + m.group(0), script, count=1)

# Expand command descriptions so fzf-tab can show both name and detail
cmd_pattern = re.compile(r'(?m)(^\s*)local _commands=\(\n(?P<body>(?:^\s+.*\n)*?)^\s*\)\n')

def repl(match):
    indent = match.group(1)
    body = match.group('body')
    if 'local -a _commands_raw' in body:
        return match.group(0)
    transformed = (
        f"{indent}local -a _commands_raw=(\n"
        f"{body}"
        f"{indent})\n"
        f"{indent}local -a _commands=()\n"
        f"{indent}local _rk_item _rk_name _rk_desc\n"
        f"{indent}for _rk_item in \"${{_commands_raw[@]}}\"; do\n"
        f"{indent}  _rk_name=${{_rk_item%%:*}}\n"
        f"{indent}  _rk_desc=${{_rk_item#*:}}\n"
        f"{indent}  _commands+=(\"${{_rk_name}}:${{_rk_name}} - ${{_rk_desc}}\")\n"
        f"{indent}done\n"
    )
    return transformed

script = cmd_pattern.sub(repl, script)

sys.stdout.write(script)
PY
}

__ami_report_kit_register_completion() {
  emulate -L zsh
  setopt localoptions
  unsetopt xtrace verbose

  # Only register once per shell
  [[ -n ${__AMI_REPORT_KIT_COMPLETION_DONE:-} ]] && return 0

  local _script
  _script=$(report-kit completion zsh --fallback 2>/dev/null) || return 0
  _script=$(__ami_report_kit_transform_script report-kit "$_script")
  eval "${_script}" || return 0

  (( ${+__AMI_REPORT_KIT_ALIAS_DONE} )) || typeset -gA __AMI_REPORT_KIT_ALIAS_DONE

  local _rk_alias _rk_alias_script
  for _rk_alias in ${(k)aliases}; do
    if [[ ${aliases[$_rk_alias]} == report-kit* && $_rk_alias != report-kit ]]; then
      [[ -n ${__AMI_REPORT_KIT_ALIAS_DONE[$_rk_alias]:-} ]] && continue
      _rk_alias_script=$(report-kit completion zsh --fallback --prog "$_rk_alias" 2>/dev/null) || continue
      _rk_alias_script=$(__ami_report_kit_transform_script "$_rk_alias" "$_rk_alias_script")
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
