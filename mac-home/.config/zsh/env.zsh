
# GNU Stow base directory
export STOW_DIR="$HOME/_env/stow"

# export HK_USE_ZHIST=1

# ==== Paths (trimmed and deduplicated) ====
export XDG_CONFIG_HOME="$HOME/.config"
# export LOCALBIN="$XDG_CONFIG_HOME/bin"
# export LOCALPROG="$HOME/prog"
export GOPATH="$HOME/go"

# Base PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"

# export PATH="$PATH:$LOCALBIN"
# export PATH="$PATH:/usr/local/bin"
# export PATH="$PATH:/opt/homebrew/bin:/opt/homebrew/sbin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/go/bin"
# export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin/"
# export PATH="$PATH:/opt/homebrew/opt/llvm/bin"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
# export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"

# Flutter/Dart (kept)
# export PATH="$HOME/fvm/default/bin:$PATH"
# export PATH="$PATH:$LOCALPROG/flutter/bin"
# export PATH="$PATH:$LOCALPROG/flutter/bin/cache/dart-sdk/bin"
# export PATH="$PATH:$HOME/.pub-cache/bin"
# export FLUTTER_ROOT="$LOCALPROG/flutter"

# Removed non-macOS or outdated paths (kept commented for reference)
# /home/linuxbrew/.linuxbrew/bin
# /home/linuxbrew/.linuxbrew/sbin
# $HOME/.linuxbrew/bin
# $HOME/.linuxbrew/sbin
# /usr/local/Cellar/node/15.0.1/bin
# /usr/local/Cellar/node/14.2.0/bin
# /usr/local/opt/node@12/bin
# /snap/bin
# Ruby GEM paths under /opt/homebrew/lib/ruby/... and $HOME/.gem/ruby/2.6.0

# ==== Shell and tooling ====
export TERM=xterm-256color
export TERM_ITALICS=true
# export RANGER_LOAD_DEFAULT_RC="false"
# export EDITOR=nvim
export EDITOR=hx
# export EDITOR='emacsclient -t'

# Light theme colors
export CLICOLOR=1
export LSCOLORS=Exfxcxdxbxegedabagacad
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#93a1a1'

# 安全兜底：确保常见变量存在，防止偶发的 nounset 影响第三方脚本
: "${NO_COLOR:=}"
: "${RANGER_LEVEL:=}"
: "${VIRTUAL_ENV:=}"
export NO_COLOR RANGER_LEVEL VIRTUAL_ENV

# Proxy 设置与便捷函数（bash/zsh 通用）
PROXY_VARS="HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy ALL_PROXY all_proxy HOMEBREW_HTTP_PROXY HOMEBREW_HTTPS_PROXY HOMEBREW_NO_PROXY"

proxy-off() {
  # 清除当前 shell 的代理；支持 --git/--npm/--all；传入 -l/--launchctl 同步清除 launchctl
  do_l=0; do_git=0; do_npm=0
  for a in "$@"; do
    case "$a" in
      -l|--launchctl) do_l=1 ;;
      --git) do_git=1 ;;
      --npm) do_npm=1 ;;
      --all) do_git=1; do_npm=1 ;;
      *) : ;;
    esac
  done
  launchflag=""; [ "$do_l" -eq 1 ] && launchflag="--launchctl" || :
  gitflag="";    [ "$do_git" -eq 1 ] && gitflag="--git" || :
  npmflag="";    [ "$do_npm" -eq 1 ] && npmflag="--npm" || :
  . "$HOME/.local/bin/set-proxy" unset ${launchflag:+$launchflag} ${gitflag:+$gitflag} ${npmflag:+$npmflag}
}

proxy-on() {
  # proxy-on [URL] [--git] [--npm] [--all] [-l|--launchctl]
  do_l=0; do_git=0; do_npm=0; url=""
  for a in "$@"; do
    case "$a" in
      -l|--launchctl) do_l=1 ;;
      --git) do_git=1 ;;
      --npm) do_npm=1 ;;
      --all) do_git=1; do_npm=1 ;;
      *) url="$a" ;;
    esac
  done
  [ -n "$url" ] || url="${PROXY_URL:-http://localhost:53373}"
  launchflag=""; [ "$do_l" -eq 1 ] && launchflag="--launchctl" || :
  gitflag="";    [ "$do_git" -eq 1 ] && gitflag="--git" || :
  npmflag="";    [ "$do_npm" -eq 1 ] && npmflag="--npm" || :
  . "$HOME/.local/bin/set-proxy" --url "$url" ${launchflag:+$launchflag} ${gitflag:+$gitflag} ${npmflag:+$npmflag}
}

# 开机默认仅在 macOS 设置一次（可通过 proxy-off 撤销；避免重复 source 覆盖）
case "$(uname -s)" in
  Darwin)
    if [ -z "${PROXY_AUTO_APPLIED:-}" ]; then
      : "${PROXY_URL:=${HTTP_PROXY:-${HTTPS_PROXY:-${ALL_PROXY:-http://localhost:53373}}}}"
      proxy-on "$PROXY_URL"
      export PROXY_AUTO_APPLIED=1
    fi
    ;;
  *) : ;;
esac

# Locale and history
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
# Avoid setting LC_ALL globally; it overrides all LC_* and can cause encoding issues
# export LC_ALL=$LANG
export HISTSIZE=100000
export SAVEHIST=100000

# Bun runtime
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Cargo env for scripts and interactive shells
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Homebrew bottles mirror: Aliyun (keep others as comments)
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
# export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
# export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles

# Visual Studio Code
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Elan (Rust toolchains)
export PATH="$HOME/.elan/bin:$PATH"

# BAT theme
export BAT_THEME="TwoDark"

# Google Gemini API Key
export GEMINI_API_KEY="AIzaSyCzZ-55AgAO2V_exRT8MhyNXK4lv4d5Kwc"

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
