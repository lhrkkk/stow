# # Homebrew: load at login to ensure /opt/homebrew/bin precedes /usr/local/bin
# if [ -x /opt/homebrew/bin/brew ]; then
#   eval "$('/opt/homebrew/bin/brew' shellenv)"
# fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
# [ ! -f "~/.orbstack/shell/init.zsh" ] || source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# IMPORTANT: System zsh functions MUST come before homebrew's site-functions
# Otherwise homebrew's bash-based _git wrapper will override the native zsh _git


# if [[ -d /usr/share/zsh/5.9/functions ]]; then
  # fpath=(/usr/share/zsh/5.9/functions $fpath)
# fi

# Homebrew site-functions (other completions from brew packages)
# NOTE: Contains a _git that's just a bash wrapper, system's _git is preferred
# fpath=($fpath /opt/homebrew/share/zsh/site-functions)
# fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# Visual Studio Code
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="$PATH:/Applications/Sublime Merge.app/Contents/SharedSupport/bin"
export PATH="$PATH:/Applications/Araxis Merge.app/Contents/Utilities"

proxy-on http://127.0.0.1:53373