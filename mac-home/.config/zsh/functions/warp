# Warp helper: open directory (default current) in a new Warp tab
# Usage:
#   warp            # 打开当前目录
#   warp <dir>      # 打开指定目录（支持相对/绝对/波浪线）
warp() {
  emulate -L zsh
  setopt local_options

  local target
  if (( $# >= 1 )); then
    target="$1"
  else
    target="$PWD"
  fi

  # 解析为绝对路径（zsh 参数修饰符 :A）
  target="${~target:A}"

  if [[ ! -d "$target" ]]; then
    echo "目录不存在: $target" >&2
    return 1
  fi

  open "warp://action/new_tab?path=$target"
}


