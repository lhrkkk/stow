# Copyright 2025 Haorui Lu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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
  # proxy-on [--http URL] [--socks URL] [--url URL] [--git] [--npm] [--all] [-l|--launchctl]
  do_l=0; do_git=0; do_npm=0; http_url=""; socks_url=""; url_both=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -l|--launchctl) do_l=1 ;;
      --git) do_git=1 ;;
      --npm) do_npm=1 ;;
      --all) do_git=1; do_npm=1 ;;
      --http)
        shift
        if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then http_url="$1"; fi
        ;;
      --socks)
        shift
        if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then socks_url="$1"; fi
        ;;
      --url)
        shift
        if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then url_both="$1"; fi
        ;;
      --) shift; break ;;
      *)
        # 兼容旧用法：单个位置参数作为 url_both
        if [ -z "$url_both" ]; then url_both="$1"; fi
        ;;
    esac
    [ $# -gt 0 ] && shift
  done
  # --url/位置参数作为 http 与 socks 的共同缺省；--http/--socks 明确指定时不受影响
  if [ -z "$http_url" ] && [ -n "$url_both" ]; then http_url="$url_both"; fi
  if [ -z "$socks_url" ] && [ -n "$url_both" ]; then socks_url="$url_both"; fi

  # 逐段构造参数字符串
  cmd=". \"$HOME/.local/bin/set-proxy\""
  [ -n "$http_url" ] && cmd="$cmd --http \"$http_url\""
  [ -n "$socks_url" ] && cmd="$cmd --socks \"$socks_url\""
  [ "$do_l" -eq 1 ] && cmd="$cmd --launchctl"
  [ "$do_git" -eq 1 ] && cmd="$cmd --git"
  [ "$do_npm" -eq 1 ] && cmd="$cmd --npm"
  eval "$cmd"
}

proxy-status() {
  . "$HOME/.local/bin/set-proxy" status
}

# # 开机默认仅在 macOS 设置一次（可通过 proxy-off 撤销；避免重复 source 覆盖）
# case "$(uname -s)" in
#   Darwin)
#     if [ -z "${PROXY_AUTO_APPLIED:-}" ]; then
#       : "${PROXY_URL:=${HTTP_PROXY:-${HTTPS_PROXY:-${ALL_PROXY:-http://localhost:53373}}}}"
#       proxy-on "$PROXY_URL"
#       export PROXY_AUTO_APPLIED=1
#     fi
#     ;;
#   Linux)
#     if [ -z "${PROXY_AUTO_APPLIED:-}" ]; then
#       : "${PROXY_URL:=http://localhost:10808}"
#       : "${PROXY_SOCKS_URL:=socks5://localhost:10809}"
#       proxy-on --http "$PROXY_URL" --socks "$PROXY_SOCKS_URL"
#       export PROXY_AUTO_APPLIED=1
#     fi
#     ;;
#   *) : ;;
# esac