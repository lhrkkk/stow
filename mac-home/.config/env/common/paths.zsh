# GNU Stow base directory
export STOW_DIR="$HOME/_env/stow"

# ==== Paths (trimmed and deduplicated) ====
export XDG_CONFIG_HOME="$HOME/.config"
export GOPATH="$HOME/go"
export PATH="$PATH:$HOME/go/bin"

# Ensure Homebrew bins are on PATH early (for tools like mise)
# for _hb in /opt/homebrew/bin /opt/homebrew/sbin /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin; do
  # [ -d "$_hb" ] && PATH="$_hb:$PATH"
# done
# unset _hb

# local
export PLATFORM=$(uname -s)
. ~/.config/env/local/${PLATFORM}.sh

# Base PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"

# export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin/"
# export PATH="$PATH:/opt/homebrew/opt/llvm/bin"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
# export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"



# Bun runtime
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# Elan (Rust toolchains)
export PATH="$HOME/.elan/bin:$PATH"

# BAT theme
export BAT_THEME="TwoDark"

# Cargo env for scripts and interactive shells
export PATH="$PATH:$HOME/.cargo/bin"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
