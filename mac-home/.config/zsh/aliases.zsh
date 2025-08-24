alias av='source venv/bin/activate'
alias c='clear'
alias cdiff='colordiff'
alias cs='calcurse'
alias dv='deactivate'
alias gc='git config credential.helper store'
alias gg='git clone'
alias ipy='ipython'
alias l='ls -la'
alias lg='lazygit'
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
alias s='neofetch'
alias g='onefetch'
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
alias cl="claude --dangerously-skip-permissions"
alias co="codex --sandbox danger-full-access"

# ---- Migrated from Bash ----
# Mosh shortcuts
alias s0="mosh root@s0"
alias s1="mosh root@s1"
alias s2="mosh root@s2"

# EZA (better ls)
alias ls="eza --color=always --icons=always --group-directories-first"
alias ll="eza --color=always --long --git --icons=always --group-directories-first"
alias la="eza --color=always --long --git --icons=always --all --group-directories-first"
alias lt="eza --color=always --tree --git --icons=always"

# Lazy-load thefuck
alias fuck="_tf_lazy"
_tf_lazy() {
	unalias fuck 2>/dev/null || true
	eval "$(thefuck --alias)"
	fuck "$@"
}

