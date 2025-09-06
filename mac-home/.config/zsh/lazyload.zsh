# 异步（事件循环延后）初始化补全系统：提示符先出来，随后在本 shell 完成 compinit
if [[ $- == *i* ]]; then
  # 捕获启动期对 compdef 的调用，避免模块在 compinit 前报错
  typeset -ga __compdef_queue
  compdef() { __compdef_queue+=("$*"); }

  _lazy_compinit_run() {
    # 释放 compdef 名字，恢复为真正的 compdef
    unfunction compdef 2>/dev/null || true

    autoload -Uz compinit
    local dump=${ZDOTDIR:-$HOME}/.zcompdump
    compinit -C -d "$dump"

    # 回放启动期间累计的 compdef 定义
    local def
    for def in "${__compdef_queue[@]}"; do eval "compdef $def"; done
    unset __compdef_queue

    # 后台预编译缓存（仅文件 I/O）
    { [[ -f $dump ]] && { [[ ! -f $dump.zwc || $dump -nt $dump.zwc ]] && zcompile "$dump"; } } &!

    # 执行一次后移除自己，防止被 Tab 兜底再次调用
    unfunction _lazy_compinit_run 2>/dev/null || true
  }

  # 如果支持 sched，则在提示符显示后的下一轮事件循环执行
  if zmodload zsh/sched 2>/dev/null; then
    sched +0 _lazy_compinit_run
  fi

  # 首次 Tab 兜底：若尚未初始化，则先运行再补全
  zle -N _ami_expand_or_complete
  _ami_expand_or_complete() {
    if typeset -f _lazy_compinit_run >/dev/null; then
      _lazy_compinit_run
    fi
    zle expand-or-complete
  }
  bindkey '^I' _ami_expand_or_complete
fi

# # Initialize completion early so fzf-tab (loaded by Zim) sees a ready system
# if [[ $- == *i* ]]; then
#   autoload -Uz compinit
#   local dump=${ZDOTDIR:-$HOME}/.zcompdump
#   compinit -C -d $dump
#   { [[ -f $dump ]] && { [[ ! -f $dump.zwc || $dump -nt $dump.zwc ]] && zcompile $dump; } } &!
# fi

# 延后加载 Zim：提示符先显示，随后加载模块并应用 prompt/autopair
_lazy_zim_init_run() {
  typeset -g _zim_inited
  [[ $_zim_inited == 1 ]] && return
  _zim_inited=1

  source "${ZIM_HOME}/init.zsh"

  # 依赖 Zim 的初始化
  autopair-init
  source ~/.config/zsh/prompt.zsh

  unfunction _lazy_zim_init_run 2>/dev/null || true
}
if zmodload zsh/sched 2>/dev/null; then
  sched +0 _lazy_zim_init_run
else
  _lazy_zim_init_run
fi


# 使用 fpath + autoload 自动注册 functions 目录中的所有函数（文件名=函数名，无扩展名）
fpath+="$HOME/.config/zsh/functions"
typeset -Ua _ami_funcs
_ami_funcs=("$HOME/.config/zsh/functions"/*(N:t))
(( $#_ami_funcs )) && autoload -Uz ${_ami_funcs}
unset _ami_funcs
