
# if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
#   eval "$('/home/linuxbrew/.linuxbrew/bin/brew' shellenv)"
# fi

# Homebrew
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Prefer an explicitly installed curl only when the binary actually exists.
if [ -x /opt/curl-8.9.1/bin/curl ]; then
  export HOMEBREW_CURL_PATH="/opt/curl-8.9.1/bin/curl"
else
  unset HOMEBREW_CURL_PATH 2>/dev/null || true
fi

proxy-on --http http://127.0.0.1:10808 --socks socks5://127.0.0.1:10809
