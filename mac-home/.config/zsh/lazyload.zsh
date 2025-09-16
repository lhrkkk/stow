export ZIM_HOME=${HOME}/.zim

# 异步（事件循环延后）初始化补全系统：提示符先出来，随后在本 shell 完成 compinit
if [[ $- == *i* ]]; then
  # 捕获启动期对 compdef 的调用，避免模块在 compinit 前报错
  typeset -ga __compdef_queue
  compdef() { __compdef_queue+=("$*"); }

  # 一次性按需加载 Git/JJ 增强补全脚本（避免启动时立即 source）
  __ami_source_completions_once() {
    [[ -n ${__AMI_COMPLETIONS_SOURCED:-} ]] && return
    # 这些脚本会定义 __ami_after_compinit 钩子，稍后在 compinit 之后触发
    source ~/.config/zsh/git-completion-enhanced.zsh
    source ~/.config/zsh/jj-completion-enhanced.zsh
    __AMI_COMPLETIONS_SOURCED=1
  }

  _lazy_compinit_run() {
    # 释放 compdef 名字，恢复为真正的 compdef
    unfunction compdef 2>/dev/null || true

    # 在 compinit 之前，确保 fpath 包含系统函数目录与 zsh-completions
    if [[ -n ${ZIM_HOME} && -d ${ZIM_HOME}/modules/zsh-completions/src ]]; then
      typeset -U fpath
      fpath=("${ZIM_HOME}/modules/zsh-completions/src" $fpath)
    fi
    # 通用系统目录（存在就加入）
    typeset -U fpath
    local _d
    for _d in \
      /usr/share/zsh/5.9/functions \
      /usr/share/zsh/functions \
      /opt/homebrew/share/zsh/site-functions \
      /usr/local/share/zsh/site-functions \
      /opt/homebrew/share/zsh/functions; do
      [[ -d $_d ]] && fpath=($_d $fpath)
    done

    autoload -Uz compinit
    # 若 compinit 文件仍不可用则直接返回，避免报错
    local _has_compinit=0
    for _d in $fpath; do [[ -r $_d/compinit ]] && _has_compinit=1 && break; done
    if (( ! _has_compinit )); then
      return 0
    fi
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

  # 首次 Tab 兜底：若尚未初始化，则先运行再补全
  zle -N _ami_expand_or_complete
  _ami_expand_or_complete() {
    # 确保补全脚本已加载（定义 after-compinit 钩子）
    __ami_source_completions_once
    if typeset -f _lazy_compinit_run >/dev/null; then
      _lazy_compinit_run
      # Allow modules to run post-compinit hooks exactly once
      if typeset -f __ami_after_compinit >/dev/null; then
        __ami_after_compinit
        unfunction __ami_after_compinit 2>/dev/null || true
      fi
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

  # 确保我们的 completion 覆盖（如 git 别名分组）在 Zim 之后仍然生效
  if typeset -f __ami_after_compinit >/dev/null; then
    __ami_after_compinit
  fi

  unfunction _lazy_zim_init_run 2>/dev/null || true
}

if [[ $- == *i* ]]; then
  autoload -Uz add-zsh-hook
  _zim_precmd_once() {
    add-zsh-hook -d precmd _zim_precmd_once 2>/dev/null || true
    # 在 compinit 之前加载补全脚本，以便 after-compinit 能在下方被调用
    __ami_source_completions_once
    # 确保在加载 Zim 与 fzf-tab 之前已经完成 compinit
    if typeset -f _lazy_compinit_run >/dev/null; then
      _lazy_compinit_run
      if typeset -f __ami_after_compinit >/dev/null; then
        __ami_after_compinit
        unfunction __ami_after_compinit 2>/dev/null || true
      fi
    fi
    _lazy_zim_init_run
  }
  add-zsh-hook precmd _zim_precmd_once
else
  _lazy_zim_init_run
fi


# 使用 fpath + autoload 自动注册 functions 目录中的所有函数（文件名=函数名，无扩展名）

typeset -U fpath
fpath+="$HOME/.config/zsh/functions"
typeset -Ua _ami_funcs
_ami_funcs=("$HOME/.config/zsh/functions"/*(N:t))
(( $#_ami_funcs )) && autoload -Uz ${_ami_funcs}
unset _ami_funcs
