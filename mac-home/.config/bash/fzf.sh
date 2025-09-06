
# ---- FZF (Fuzzy Finder) -----
# Key bindings loaded immediately (3ms) for Ctrl+T/R to work
# Completion scripts lazy-loaded to save startup time
# Using static scripts saves ~19ms vs eval "$(fzf --bash)"
if command -v brew >/dev/null 2>&1; then
  FZF_BASE="$(brew --prefix)/opt/fzf/shell"
  [ -f "$FZF_BASE/key-bindings.bash" ] && source "$FZF_BASE/key-bindings.bash"

  # Lazy-load completion only
  _fzf_lazy_completion() {
    if [ -z "$FZF_COMPLETION_LOADED" ]; then
      [ -f "$FZF_BASE/completion.bash" ] && source "$FZF_BASE/completion.bash"
      export FZF_COMPLETION_LOADED=1
    fi
  }

  # Hook into the completion system
  complete -F _fzf_lazy_completion -o default -o bashdefault fzf
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
