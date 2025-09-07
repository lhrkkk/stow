
# if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
#   eval "$('/home/linuxbrew/.linuxbrew/bin/brew' shellenv)"
# fi

# Homebrew
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"

export HOMEBREW_CURL_PATH="/opt/curl-8.9.1/bin/curl"

proxy-on --http http://127.0.0.1:10808 --socks socks5://127.0.0.1:10809