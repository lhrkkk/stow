# # Homebrew: load at login to ensure /opt/homebrew/bin precedes /usr/local/bin
# if [ -x /opt/homebrew/bin/brew ]; then
#   eval "$('/opt/homebrew/bin/brew' shellenv)"
# fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
# [ ! -f "~/.orbstack/shell/init.zsh" ] || source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# Visual Studio Code
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

proxy-on http://127.0.0.1:53373