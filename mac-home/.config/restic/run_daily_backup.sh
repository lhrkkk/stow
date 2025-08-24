#!/usr/bin/env bash
# 自动运行的 restic 备份包装脚本
# - 设置 PATH（包括 Homebrew）
# - 切换到 ~/.config/restic
# - 加载 .env.private（提供 RESTIC_PASSWORD 等）
# - 执行备份脚本，并将输出写入日志（由 plist 负责重定向）
set -euo pipefail

# 确保 PATH 包含 Homebrew 与用户本地 bin
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

cd "$HOME/.config/restic"

# 加载私密环境变量（如果存在）
if [ -f ./.env.private ]; then
  set -a
  # shellcheck disable=SC1091
  source ./.env.private
  set +a
fi

# 可选：允许 .envrc 的变量（不要求安装 direnv）
if [ -f ./.envrc ]; then
  # shellcheck disable=SC1091
  source ./.envrc || true
fi

# 执行备份
./backup_restic_pcloud

