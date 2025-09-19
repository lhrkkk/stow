#!/usr/bin/env zsh
# Shared completion and fzf-tab styles.

# Base completion behaviour tuned for fzf-tab.
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'

# fzf-tab theme (Selenized Light - Gogh).
typeset -a _ami_fzf_tab_theme=(
  --ansi
  '--color=light,fg+:#3a4d53,bg+:#e9e4d4,hl+:#0072d4,info:#009c8f,prompt:#c25d1e,spinner:#ca4898,pointer:#0072d4,marker:#ad8900,header:#489100'
)
zstyle ':fzf-tab:*' fzf-flags ${_ami_fzf_tab_theme[@]}
zstyle ':fzf-tab:*' show-group yes

# --- git 专用（fzf-tab） ---
zstyle ':fzf-tab:complete:git:*' fzf-flags ${_ami_fzf_tab_theme[@]} --no-sort
zstyle ':fzf-tab:complete:git:*' descriptions yes

# --- report-kit / rk ---
zstyle ':completion:*:*:(report-kit|rk):*' verbose yes
zstyle ':completion:*:*:(report-kit|rk):*:descriptions' format '%F{244}%d%f'
zstyle ':completion:*:*:(report-kit|rk):*' menu select
zstyle ':fzf-tab:complete:report-kit:*' descriptions yes
zstyle ':fzf-tab:complete:rk:*'         descriptions yes
zmodload -i zsh/complist || true
