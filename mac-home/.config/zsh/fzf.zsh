export FZF_DEFAULT_OPTS='--color=light,fg:#3a4d53,bg:#fbf3db,hl:#0072d4,fg+:#3a4d53,bg+:#e9e4d4,hl+:#0072d4,info:#009c8f,prompt:#c25d1e,spinner:#ca4898,pointer:#0072d4,marker:#ad8900,header:#489100 --bind=ctrl-t:top,change:top --bind=ctrl-j:down,ctrl-k:up'
# export FZF_DEFAULT_OPTS='--bind=ctrl-t:top,change:top --bind ctrl-e:down,ctrl-u:up'

#export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up --preview "[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500"'
#export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_DEFAULT_COMMAND='fd'
export FZF_COMPLETION_TRIGGER='\'
export FZF_TMUX=1
export FZF_TMUX_HEIGHT='80%'
export fzf_preview_cmd='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500'


_fzf_fpath=${0:h}/fzf
fpath+=$_fzf_fpath
# 允许目录为空：先收集匹配的函数名（含普通文件与符号链接），再按需 autoload
typeset -a _fzf_funcs
for _f in ${_fzf_fpath}/*(N); do
  [[ -f $_f || -h $_f ]] || continue
  _fzf_funcs+=(${_f:t})
done
if (( $#_fzf_funcs )); then
  autoload -U ${_fzf_funcs}
fi
unset _fzf_fpath _fzf_funcs _f

fzf-redraw-prompt() {
	local precmd
	for precmd in $precmd_functions; do
		$precmd
	done
	zle reset-prompt
}
zle -N fzf-redraw-prompt

zle -N fzf-find-widget
bindkey '^p' fzf-find-widget

fzf-cd-widget() {
	local tokens=(${(z)LBUFFER})
	if (( $#tokens <= 1 )); then
		zle fzf-find-widget 'only_dir'
		if [[ -d $LBUFFER ]]; then
			cd $LBUFFER
			local ret=$?
			LBUFFER=
			zle fzf-redraw-prompt
			return $ret
		fi
	fi
}
zle -N fzf-cd-widget
bindkey '^t' fzf-cd-widget

fzf-history-widget() {
	local num had_fhistory=0
	if whence -w fhistory >/dev/null 2>&1; then
		had_fhistory=1
		num=$(fhistory $LBUFFER)
		local fh_ret=$?
		# 取消/无选择：直接返回，不进入 bck-i-search
		if (( fh_ret != 0 )); then
			zle reset-prompt
			return 0
		fi
	else
		num=""
	fi
	if [[ -n $num ]]; then
		zle vi-fetch-history -n $num
	else
		# 仅当缺少 fhistory 时才回退到增量历史搜索
		if (( ! had_fhistory )); then
			zle history-incremental-search-backward || zle history-beginning-search-backward
		fi
	fi
	zle reset-prompt
	return 0
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget


fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

find-in-file() {
	grep --line-buffered --color=never -r "" * | fzf
}
zle -N find-in-file
bindkey '^f' find-in-file

