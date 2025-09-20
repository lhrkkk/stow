typeset -gA _ami_fzf_color_flags=(
  # 默认（浅色）
  light '--color=light,fg:#3a4d53,bg:#fbf3db,hl:#0072d4,fg+:#3a4d53,bg+:#e9e4d4,hl+:#0072d4,info:#009c8f,prompt:#c25d1e,spinner:#ca4898,pointer:#0072d4,marker:#ad8900,header:#489100,gutter:#fbf3db'
  # 深色
  dark  '--color=dark,fg:#dce2f1,bg:#1b1f28,hl:#4f9cff,fg+:#dce2f1,bg+:#2a3240,hl+:#4f9cff,info:#36c2b2,prompt:#fbc02d,spinner:#f06292,pointer:#4f9cff,marker:#ffb300,header:#8bc34a,gutter:#1b1f28'
)

typeset -ga _ami_fzf_default_bindings=(
  '--bind=ctrl-t:top,change:top'
  '--bind=ctrl-j:down,ctrl-k:up'
)

typeset -gi _ami_fzf_theme_ready=0

ami-fzf-theme-once() {
  (( $+functions[ami-fzf-ensure-theme] )) || return 0
  ami-fzf-ensure-theme
}

ami-fzf-resolve-theme() {
  local requested=${1:-}
  local variant

  if [[ -n $requested ]]; then
    variant=${requested:l}
  elif [[ -n ${AMI_FZF_THEME_OVERRIDE:-} ]]; then
    variant=${AMI_FZF_THEME_OVERRIDE:l}
  elif [[ -n ${AMI_FZF_THEME_VARIANT:-} ]]; then
    variant=${AMI_FZF_THEME_VARIANT:l}
  else
    local script="$HOME/.local/bin/check_term_theme.py"
    if [[ -x $script ]]; then
      variant=$($script --quiet --fallback light 2>/dev/null | tr -d '[:space:]')
    fi
  fi

  [[ -n $variant ]] || variant=light
  print -r -- ${variant:l}
}

ami-fzf-apply-theme() {
  local variant
  variant=$(ami-fzf-resolve-theme "$1")
  [[ -n ${_ami_fzf_color_flags[$variant]:-} ]] || variant=light
  typeset -gx AMI_FZF_THEME_VARIANT=$variant

  local color_flag=${_ami_fzf_color_flags[$variant]}
  typeset -ga _ami_fzf_default_opts=(
    '--ansi'
    "$color_flag"
    ${_ami_fzf_default_bindings[@]}
  )
  typeset -gx FZF_DEFAULT_OPTS="${(j: :)_ami_fzf_default_opts}"

  if [[ ${+_ami_fzf_color_flags} -gt 0 ]]; then
    typeset -gx _ami_fzf_current_color_flag=$color_flag
    local -a _ami_fzf_tab_flags=(--ansi "$color_flag")
    zstyle ':fzf-tab:*' fzf-flags ${_ami_fzf_tab_flags[@]}
    zstyle ':fzf-tab:complete:git:*' fzf-flags ${_ami_fzf_tab_flags[@]} --no-sort
    unset _ami_fzf_tab_flags
  fi

  _ami_fzf_theme_ready=1
}

ami-fzf-ensure-theme() {
  if (( _ami_fzf_theme_ready )); then
    return 0
  fi

  if [[ ${FZF_DEFAULT_OPTS:-} == *"--color=light,"* || ${FZF_DEFAULT_OPTS:-} == *"--color=dark,"* ]]; then
    _ami_fzf_theme_ready=1
    return 0
  fi

  ami-fzf-apply-theme "$@"
}

# 在首次 Tab（lazyload）触发之前，先提供一个中性的默认值。
typeset -gx FZF_DEFAULT_OPTS='--ansi --bind=ctrl-t:top,change:top --bind=ctrl-j:down,ctrl-k:up'

if ! (( $+functions[fzf] )); then
  fzf() {
    # ami-fzf-theme-once
    command fzf "$@"
  }
fi

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
	ami-fzf-theme-once
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
	ami-fzf-theme-once
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
  ami-fzf-theme-once
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

find-in-file() {
	ami-fzf-theme-once
	grep --line-buffered --color=never -r "" * | fzf
}
zle -N find-in-file
bindkey '^f' find-in-file
