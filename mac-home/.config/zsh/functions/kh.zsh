#compdef kh
# kh — 交互式删除 zsh 历史（基于 fzf）
# - Tab 多选，Enter 确认
# - 删除后写回 $HISTFILE，并提示结果
# 依赖: fzf, zsh 5+

function kh {
  emulate -L zsh -o extendedglob -o noaliases

  local histfile
  histfile="${HISTFILE:-$HOME/.zsh_history}"

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -- "kh: 需要 fzf，请先安装"
    return 1
  fi

  local limit list
  limit="${KH_LIMIT:-5000}"
  list=$(fc -l -r 1 | head -n "$limit") || return 0
  if [[ -z "$list" ]]; then
    print -- "无历史记录"
    return 0
  fi

  local header sel
  header="选择要删除的历史（Tab 多选，Enter 确认；Ctrl-C 取消）"
  sel=$(printf "%s\n" "$list" | \
    FZF_DEFAULT_OPTS="" fzf --multi --no-sort --tiebreak=index \
      --height=80% --layout=reverse --info=inline \
      --prompt='删除历史> ' --header="$header" \
      --bind='ctrl-a:toggle-all,tab:toggle+down,shift-tab:toggle+up' \
      --preview 'echo {}' --preview-window=down,3,wrap) || return 0

  local -a nums
  nums=(${(f)"$(printf "%s\n" "$sel" | awk '{print $1}')"})
  local n
  n=${#nums}
  if (( n == 0 )); then
    print -- "未选择，已取消"
    return 0
  fi

  # 确认
  local REPLY
  read -q "REPLY?确认删除 ${n} 条历史记录？[y/N] " || { echo; print -- "已取消"; return 0; }
  echo

  # 备份 HISTFILE（可通过 KH_BACKUP=0 关闭）
  if [[ "${KH_BACKUP:-1}" = 1 && -f "$histfile" ]]; then
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    cp -p "$histfile" "${histfile}.bak.${ts}" 2>/dev/null || true
  fi

  # 倒序删除以避免编号位移
  local -a dnums
  dnums=(${(On)nums})   # 数值降序排序

  local c=0 num
  for num in $dnums; do
    builtin history -d "$num" 2>/dev/null && ((c++))
  done

  # 写回文件
  fc -W "$histfile"

  print -- "已删除 ${c}/${n} 条，并写回：$histfile"
  return 0
}

# 简单帮助
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  cat <<'KH_HELP'
kh - 交互式删除 zsh 历史（基于 fzf）
用法：
  kh               打开历史选择器（Tab 多选，Enter 确认）
环境变量：
  KH_LIMIT=5000    限制加载的历史条数（默认 5000）
  KH_BACKUP=1      删除前备份 HISTFILE（默认 1）
说明：
  - 删除发生在当前 shell 的内存历史中，并用 fc -W 写回 HISTFILE。
  - 其他已打开的 shell 会话下次写回或读取历史时才会反映变化。
KH_HELP
fi

