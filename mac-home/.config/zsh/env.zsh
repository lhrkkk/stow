# ==== Paths (trimmed and deduplicated) ====
export XDG_CONFIG_HOME="$HOME/.config"
# export LOCALBIN="$XDG_CONFIG_HOME/bin"
# export LOCALPROG="$HOME/prog"
export GOPATH="$HOME/go"

# Base PATH
export PATH="$HOME/.local/bin:$PATH"
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
export EDITOR=nvim

# Light theme colors
export CLICOLOR=1
export LSCOLORS=Exfxcxdxbxegedabagacad
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#93a1a1'

# Proxy settings
export http_proxy="http://127.0.0.1:53373"
export https_proxy="http://127.0.0.1:53373"
export all_proxy="socks5://127.0.0.1:53373"
export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$https_proxy"
export ALL_PROXY="$all_proxy"

# Locale and history
export LANG=en_US.UTF-8
export LC_ALL=$LANG
export HISTSIZE=100000
export SAVEHIST=100000

# Bun runtime
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Cargo env for scripts and interactive shells
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

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

# ==== Lazy-load Conda (keep) ====
conda() {
  unset -f conda
  __conda_setup="\"$HOME/miniconda3/bin/conda\" shell.zsh hook 2>/dev/null"
  __conda_eval=$(eval ${=__conda_setup})
  if [ $? -eq 0 ]; then
    eval "$__conda_eval"
  elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
  else
    export PATH="$HOME/miniconda3/bin:$PATH"
  fi
  unset __conda_setup __conda_eval
  conda "$@"
}
