# ==== Shell and tooling ====
export TERM=xterm-256color
export TERM_ITALICS=true
# export RANGER_LOAD_DEFAULT_RC="false"
# export EDITOR=nvim
# export EDITOR=hx
export EDITOR='emacsclient -t'

# export WEZ_RES_AUTO_SAVE=1


# Locale and history
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
# Avoid setting LC_ALL globally; it overrides all LC_* and can cause encoding issues
# export LC_ALL=$LANG
export HISTSIZE=100000
export SAVEHIST=100000

# Light theme colors
export CLICOLOR=1
export LSCOLORS=Exfxcxdxbxegedabagacad
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#93a1a1'

# Homebrew bottles mirror: Aliyun (keep others as comments)
# export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
# export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
# export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles

export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

# export ZOXIDE_USE_CD=1