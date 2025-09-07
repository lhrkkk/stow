
# ---- FZF (Fuzzy Finder) -----
# Key bindings loaded immediately (3ms) for Ctrl+T/R to work
# Completion scripts lazy-loaded to save startup time
# Using static scripts saves ~19ms vs eval "$(fzf --bash)"
# Lazy-load fzf key-bindings and completion on first use
__fzf_bash_loaded=0
__fzf_bash_lazy_load() {
  if [ "$__fzf_bash_loaded" -eq 0 ]; then
    # Detect FZF_BASE cheaply; only call brew if necessary
    if [ -z "${FZF_BASE:-}" ]; then
      if [ -d "/opt/homebrew/opt/fzf/shell" ]; then
        FZF_BASE="/opt/homebrew/opt/fzf/shell"
      elif [ -d "/usr/local/opt/fzf/shell" ]; then
        FZF_BASE="/usr/local/opt/fzf/shell"
      elif command -v brew >/dev/null 2>&1; then
        FZF_BASE="$(brew --prefix)/opt/fzf/shell"
      else
        FZF_BASE=""
      fi
    fi
    [ -n "$FZF_BASE" ] && [ -f "$FZF_BASE/key-bindings.bash" ] && source "$FZF_BASE/key-bindings.bash"
    [ -n "$FZF_BASE" ] && [ -f "$FZF_BASE/completion.bash" ] && source "$FZF_BASE/completion.bash"
    __fzf_bash_loaded=1
  fi
}

# Only set up bindings/completions in interactive shells
if [[ $- == *i* ]]; then
  # Lazy completion loader: load real scripts, then delegate to the actual function
  _fzf_lazy_completion() {
    __fzf_bash_lazy_load
    local cmd="${COMP_WORDS[0]}" spec func
    spec=$(complete -p -- "$cmd" 2>/dev/null || true)
    func=$(echo "$spec" | awk '{for(i=1;i<=NF;i++){ if($i=="-F"){print $(i+1); exit}}}')
    if [ -n "$func" ] && [ "$func" != "_fzf_lazy_completion" ] && declare -F "$func" >/dev/null; then
      "$func"
      return
    fi
    # Fallback to generic fzf completion if available
    if declare -F _fzf_complete >/dev/null; then
      _fzf_complete
      return
    fi
  }
  complete -F _fzf_lazy_completion -o default -o bashdefault fzf
  # Also hook common fzf-enhanced commands to trigger lazy load on first Tab
  complete -F _fzf_lazy_completion -o default -o bashdefault cd
  complete -F _fzf_lazy_completion -o default -o bashdefault export
  complete -F _fzf_lazy_completion -o default -o bashdefault unset
  complete -F _fzf_lazy_completion -o default -o bashdefault ssh

  # Minimal lazy key bindings: load real bindings on first press, then delegate
  __fzf_bash_ctrl_t() {
    __fzf_bash_lazy_load
    if declare -F __fzf_select__ >/dev/null; then
      __fzf_select__
    else
      local sel
      sel=$( eval "${FZF_CTRL_T_COMMAND:-\"fd --hidden --strip-cwd-prefix --exclude .git\"}" | fzf ${FZF_CTRL_T_OPTS:+$FZF_CTRL_T_OPTS} ) || return
      READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${sel}${READLINE_LINE:READLINE_POINT}"
      READLINE_POINT=$(( READLINE_POINT + ${#sel} ))
    fi
  }
  __fzf_bash_ctrl_r() {
    __fzf_bash_lazy_load
    if declare -F __fzf_history__ >/dev/null; then
      __fzf_history__
    else
      local cmd
      cmd=$(HISTTIMEFORMAT= builtin history | fzf | sed 's/ *[0-9]\+ *//') || return
      READLINE_LINE="$cmd"
      READLINE_POINT=${#READLINE_LINE}
    fi
  }
  __fzf_bash_alt_c() {
    __fzf_bash_lazy_load
    if declare -F __fzf_cd__ >/dev/null; then
      __fzf_cd__
    else
      local dir
      dir=$(fd --type=d --hidden --strip-cwd-prefix --exclude .git | fzf) || return
      builtin cd -- "$dir"
    fi
  }
  bind -x '"\C-t":"__fzf_bash_ctrl_t"'
  bind -x '"\C-r":"__fzf_bash_ctrl_r"'
  bind -x '"\ec":"__fzf_bash_alt_c"'
fi

# -- Use fd instead of fzf --
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

# Setup fzf previews
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}' " "$@" ;;
    ssh)          fzf --preview 'dig {}' "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}
