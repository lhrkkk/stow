alias et="emacsclient -a false -e '(server-running-p)'"
alias etq="emacsclient -t -e '(save-buffers-kill-emacs)'"  #提示
alias eq="emacsclient  -e '(save-buffers-kill-emacs)'"  #提示
alias ek="pkill -f 'Emacs.app/Contents/MacOS/Emacs-arm64-11 --bg-daemon='"  #不保存

alias et='emacsclient -t -a ""'
# alias es='emacsclient -n '   # send to the latest acitive client
alias e=ew
alias h=hx

alias ee='subl ~/_env/stow'
alias ec='cursor ~/_env/stow'

alias gtc='gitui -t catppuccin-macchiato.ron'
alias lj='lazyjj'
alias lg='gitui -t latte.ron'
alias j='jj'
# alias g='git'
# alias gg='git sf'

g() {
  if [ $# -eq 0 ]; then
    git sf
  else
    git "$@"
  fi
}
alias gg='g'

alias rk='report-kit'
alias jc='jj-commit-ai --commit --chinese --bracket-title-cn'
alias gc='git-commit-ai --commit --chinese --bracket-title-cn'

alias d='delta'

alias f='fuck'
alias fk='fuck'
alias av='source venv/bin/activate'
# alias c='clear'
alias c='specstory run'
alias cl='claude-code-log --tui'
alias clf='claude-code-log --clear-html && claude-code-log --open-browser'
alias cs='bunx ccusage'
# alias cdiff='colordiff'
# alias cs='calcurse'
alias dv='deactivate'
# alias gc='git config credential.helper store'
# alias gg='git clone'
alias ipy='ipython'
alias l='ls -la'
# alias lg='lazygit'
alias ms='mailsync'
alias mt='neomutt'
alias r='echo $RANGER_LEVEL'
alias pu='python3 -m pudb'
alias ra='yazi'
# ra() {
	#if [ -z "$RANGER_LEVEL" ]
	#then
		#ranger
	#else
		#exit
	#fi
#}
# alias s='neofetch'
# alias g='onefetch'
alias sra='sudo -E yazi'
# alias sudo='sudo -E'
alias vim='nvim'
alias gs='git config credential.helper store'
alias ac='sudo tlp ac'
alias gy='git-yolo'
alias nb='newsboat -r'
alias nt="sh -c 'cd $(pwd); st' > /dev/null 2>&1 &"
alias ta='tmux a'
alias t='tmux'
alias lo='lsof -p $(fps) +w'
alias py="python"
# alias cl="claude --dangerously-skip-permissions"
alias co="codex --sandbox danger-full-access"
# Codex helpers
alias ca="codex --model gpt-5-codex --full-auto"
alias cf="codex --model gpt-5-codex --dangerously-bypass-approvals-and-sandbox"

# ---- Migrated from Bash ----
# Mosh shortcuts
alias s0="ssh root@s0"
alias s1="ssh root@s1"
alias s2="ssh root@s2"

# EZA (better ls)
alias ls="eza --color=always --group-directories-first"
alias ll="eza --color=always --long --git --icons=always --group-directories-first"
alias la="eza --color=always --long --git --icons=always --all --group-directories-first"
alias lt="eza --color=always --tree --git --icons=always"


# # Lazy-load thefuck (safe; avoids alias recursion)
# if (( $+commands[thefuck] )); then
#   fuck() {
#     emulate -L zsh -o no_aliases
#     # Install official implementation for subsequent calls
#     eval "$(thefuck --alias)"
#     # Run the same logic immediately for this first call (don’t call 'fuck' again)
#     TF_PYTHONIOENCODING=$PYTHONIOENCODING
#     export TF_SHELL=zsh
#     export TF_ALIAS=fuck
#     TF_SHELL_ALIASES=$(alias)
#     export TF_SHELL_ALIASES
#     TF_HISTORY="$(fc -ln -10)"
#     export TF_HISTORY
#     export PYTHONIOENCODING=utf-8
#     TF_CMD=$(
#       thefuck THEFUCK_ARGUMENT_PLACEHOLDER "$@"
#     ) && eval $TF_CMD
#     unset TF_HISTORY
#     export PYTHONIOENCODING=$TF_PYTHONIOENCODING
#     test -n "$TF_CMD" && print -s $TF_CMD
#   }
# fi

alias cds="cd $STOW_DIR"
