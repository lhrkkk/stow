
# ==== Lazy-load Conda (bash/zsh 通用，POSIX 语法) ====
conda() {
  # 移除自身定义，准备真正初始化
  unset -f conda 2>/dev/null || true

  CONDA_BIN="$HOME/miniconda3/bin/conda"
  if [ -x "$CONDA_BIN" ]; then
    local_shell="sh"
    [ -n "${ZSH_VERSION-}" ] && local_shell="zsh"
    [ -n "${BASH_VERSION-}" ] && local_shell="bash"

    __conda_eval="$($CONDA_BIN "shell.$local_shell" hook 2>/dev/null || true)"
    if [ -n "$__conda_eval" ]; then
      eval "$__conda_eval"
    elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
      . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
      PATH="$HOME/miniconda3/bin:$PATH"; export PATH
    fi
    unset __conda_eval local_shell CONDA_BIN
    command conda "$@"
    return $?
  else
    printf '%s\n' "conda 未找到：$CONDA_BIN" >&2
    return 127
  fi
}
 
 

# 通用注册/卸载：precmd（zsh）或 PROMPT_COMMAND（bash）
_ami_precmd_register() {
  _fn="$1"
  if [ -n "${ZSH_VERSION-}" ]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd "$_fn"
  elif [ -n "${BASH_VERSION-}" ]; then
    if [ -n "${PROMPT_COMMAND-}" ]; then
      PROMPT_COMMAND="$_fn; ${PROMPT_COMMAND}"
    else
      PROMPT_COMMAND="$_fn"
    fi
  fi
}

_ami_precmd_unregister() {
  _fn="$1"
  if [ -n "${ZSH_VERSION-}" ]; then
    add-zsh-hook -d precmd "$_fn" 2>/dev/null || true
  elif [ -n "${BASH_VERSION-}" ]; then
    case ";${PROMPT_COMMAND-};" in
      *";${_fn};"*) PROMPT_COMMAND="${PROMPT_COMMAND/$_fn; /}";;
      *";${_fn}"*)  PROMPT_COMMAND="${PROMPT_COMMAND/$_fn/}";;
    esac
  fi
}

# direnv 懒加载（bash/zsh 通用）：首个提示符初始化一次
# 仅在交互式且存在 direnv 时启用
_lazy_is_interactive=0
case "$-" in *i*) _lazy_is_interactive=1;; esac
if [ "$_lazy_is_interactive" -eq 1 ] && command -v direnv >/dev/null 2>&1; then
  _lazy_direnv_init() {
    [ -n "${_LAZY_DIRENV_INITIALIZED:-}" ] && return 0
    _lazy_shell="sh"
    [ -n "${ZSH_VERSION-}" ] && _lazy_shell="zsh"
    [ -n "${BASH_VERSION-}" ] && _lazy_shell="bash"
    eval "$(direnv hook "$_lazy_shell")"
    # 同步当前目录环境，避免错过初始目录的 .envrc
    if command -v _direnv_hook >/dev/null 2>&1; then
      _direnv_hook
    fi
    _LAZY_DIRENV_INITIALIZED=1
  }
  _lazy_direnv_once() {
    _lazy_direnv_init
    _ami_precmd_unregister _lazy_direnv_once
    unset -f _lazy_direnv_once 2>/dev/null || true
  }
  _ami_precmd_register _lazy_direnv_once
fi



# thefuck: direct correction function (bash/zsh 通用)，不安装 alias
# 优先覆盖已有 alias，避免提示
alias fuck >/dev/null 2>&1 && unalias fuck 2>/dev/null || true
fuck() {
  if ! command -v thefuck >/dev/null 2>&1; then
    for _p in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [ -x "$_p" ] && eval "$("$_p" shellenv)" && break
    done
    hash -r 2>/dev/null || true
  fi
  if ! command -v thefuck >/dev/null 2>&1; then
    printf '%s\n' "thefuck 未安装或未在 PATH 中" >&2
    return 127
  fi
  _tf_shell="zsh"
  [ -n "${BASH_VERSION-}" ] && _tf_shell="bash"
  _last="$(fc -ln -1 2>/dev/null || true)"
  case "$_last" in
    fuck*|eval\ *fuck*) eval "$(TF_ALIAS=fuck TF_SHELL=\"$_tf_shell\" thefuck $(fc -ln -2 | head -n 1))" ;;
    *)                  eval "$(TF_ALIAS=fuck TF_SHELL=\"$_tf_shell\" thefuck $(fc -ln -1))" ;;
  esac
}

# # zoxide: portable init (optional cd override via ZOXIDE_USE_CD=1)
# if command -v zoxide >/dev/null 2>&1; then
#   _zx_shell="zsh"
#   [ -n "${BASH_VERSION-}" ] && _zx_shell="bash"
#   if [ "${ZOXIDE_USE_CD:-0}" = "1" ]; then
#     eval "$(zoxide init "$_zx_shell" --cmd cd)"
#   else
#     eval "$(zoxide init "$_zx_shell")"
#   fi
# fi


# 懒加载 zoxide：第一次调用 z/zi 时才真正 init
if command -v zoxide >/dev/null 2>&1; then
  _load_zoxide() {
    unset -f z zi        # 先移除占位函数
    _zx_shell="zsh"
    [ -n "${BASH_VERSION-}" ] && _zx_shell="bash"
    if [ "${ZOXIDE_USE_CD:-0}" = "1" ]; then
      eval "$(zoxide init "$_zx_shell" --cmd cd)"
    else
      eval "$(zoxide init "$_zx_shell")"
    fi
  }
  z()  { _load_zoxide; z  "$@"; }   # 复用本次调用的参数
  zi() { _load_zoxide; zi "$@"; }
fi


# # 懒加载 zoxide：第一次调用 z/zi 时才真正 init
# if command -v zoxide >/dev/null 2>&1; then
#   _load_zoxide() {
#     unset -f z zi        # 先移除占位函数
#     eval "$(zoxide init zsh)"   # 真正初始化 zoxide
#   }
#   z()  { _load_zoxide; z  "$@"; }   # 复用本次调用的参数
#   zi() { _load_zoxide; zi "$@"; }
# fi

# eval "$(zoxide init "zsh")"


# ==== Lazy-load Homebrew environment (bash/zsh 通用) ====
# 延迟执行 brew shellenv，避免启动额外 ~20-30ms
# 选择第一个可执行的 brew 路径
BREW_BIN=""
for _p in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -x "$_p" ] && BREW_BIN="$_p" && break
done
unset _p
if [ -n "$BREW_BIN" ]; then
  brew() {
    eval "$("$BREW_BIN" shellenv)"
    unset -f brew 2>/dev/null || true
    command brew "$@"
  }
fi

# 1) 只加载 shims（快速）
export PATH="$HOME/.local/share/mise/shims:$PATH"

# 2) 懒加载一次（bash/zsh 通用）：首个提示符执行一次 hook-env，之后不再运行

_mise_hook_once() {
  # 确保能找到 mise（二次兜底：常见安装路径）
  if ! command -v mise >/dev/null 2>&1; then
    for _mb in /opt/homebrew/bin/mise /home/linuxbrew/.linuxbrew/bin/mise "$HOME/.local/bin/mise"; do
      [ -x "$_mb" ] && PATH="$(dirname "$_mb"):$PATH" && break
    done
    unset _mb
  fi
  command -v mise >/dev/null 2>&1 || { return 0; }
  eval "$(mise hook-env -q)"
  # 自卸载（统一入口）
  _ami_precmd_unregister _mise_hook_once
  unset -f _mise_hook_once 2>/dev/null || true
}

# 一次性注册（bash/zsh 通用调用）
_ami_precmd_register _mise_hook_once

# 3) 删掉/注释掉原来的：
# eval "$(mise activate zsh)"
# eval "$(mise hook-env)"


# x-cmd 懒加载：首次调用 x/xc 时再加载，避免启动开销
# [ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" # boot up x-cmd.
__x_cmd_lazy_boot() {
  # 已加载则跳过
  if [ -n "${__X_CMD_LOADED:-}" ]; then
    return 0
  fi
  xrc="$HOME/.x-cmd.root/X"
  if [ -r "$xrc" ]; then
    . "$xrc"
    __X_CMD_LOADED=1
  else
    printf '%s\n' "x-cmd 未安装或缺少 $xrc" >&2
  fi
  # 保留函数，后续重复调用开销极小
}

# 包装 x 与 xc：第一次调用触发加载
x()  { __x_cmd_lazy_boot; command x  "$@"; }
xc() { __x_cmd_lazy_boot; command xc "$@"; }

# Manual refresh helpers
mise-refresh() {
  command -v mise >/dev/null 2>&1 || return 0
  eval "$(mise hook-env -q)"
  { hash -r 2>/dev/null || rehash 2>/dev/null || true; }
}

env-rehash() { hash -r 2>/dev/null || rehash 2>/dev/null || true; }
