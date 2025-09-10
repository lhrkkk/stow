#!/usr/bin/env zsh

# Non-lazy Zsh environment initialization for debugging
# This replicates the effects of lazyload.zsh but runs immediately.

export ZIM_HOME=${HOME}/.zim

# Initialize completion immediately (interactive shells)
if [[ $- == *i* ]]; then
  autoload -Uz compinit
  local dump=${ZDOTDIR:-$HOME}/.zcompdump
  compinit -C -d "$dump"
  { [[ -f $dump ]] && { [[ ! -f $dump.zwc || $dump -nt $dump.zwc ]] && zcompile "$dump"; } } &!

  # Allow modules to run post-compinit hooks exactly once if defined
  if typeset -f __ami_after_compinit >/dev/null; then
    __ami_after_compinit
    unfunction __ami_after_compinit 2>/dev/null || true
  fi
fi

# Load Zim framework immediately
if [[ -r "${ZIM_HOME}/init.zsh" ]]; then
  source "${ZIM_HOME}/init.zsh"
fi

# Initialize features that depend on Zim
if typeset -f autopair-init >/dev/null; then
  autopair-init
fi
[[ -r ~/.config/zsh/prompt.zsh ]] && source ~/.config/zsh/prompt.zsh

# Autoload all functions from ~/.config/zsh/functions (filename == function name)
typeset -U fpath
fpath+="$HOME/.config/zsh/functions"
typeset -Ua _ami_funcs
_ami_funcs=("$HOME/.config/zsh/functions"/*(N:t))
(( $#_ami_funcs )) && autoload -Uz ${_ami_funcs}
unset _ami_funcs

# Mark as initialized for parity with lazy variant
typeset -g _zim_inited=1