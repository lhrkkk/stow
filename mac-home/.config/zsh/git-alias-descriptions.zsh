#!/usr/bin/env zsh
# Git alias descriptions for completion system
# This file adds descriptions to git aliases shown during tab completion

# Add git alias descriptions via user-commands
# This supplements the native git alias extraction with better descriptions

# Define user commands with descriptions
zstyle ':completion:*:*:git:*' user-commands \
  'ad:使用 Araxis Merge 对比目录级改动' \
  'ads:使用 Araxis Merge 对比暂存区改动' \
  'append:[Town] 在当前分支后追加新分支' \
  'hack:[Town] 创建新的 feature 分支' \
  'kill:[Town] 删除当前分支并切回父分支' \
  'new-pull-request:[Town] 创建 PR' \
  'prepend:[Town] 在当前分支前插入新分支' \
  'prune-branches:[Town] 清理已合并的分支' \
  'rename-branch:[Town] 重命名当前分支' \
  'repo:[Town] 在浏览器中打开仓库' \
  'ship:[Town] 合并当前分支到主分支' \
  'sync:[Town] 同步当前分支与远程' \
  'init:初始化仓库（默认分支 main）' \
  'cl:克隆仓库' \
  'clg:从 GitHub 克隆（HTTPS）' \
  'clgp:从 GitHub 克隆（SSH）' \
  'clgu:从 GitHub 克隆自己的仓库' \
  's:查看状态' \
  'st:查看状态' \
  'stat:查看状态' \
  'sf:简洁状态 + diff 统计' \
  'default:显示状态和最近 20 条日志' \
  'l:简洁图形化日志' \
  'lg:美化图形化日志（所有分支）' \
  'changes:显示提交的文件变化' \
  'short:简洁格式日志' \
  'simple:极简日志（仅提交信息）' \
  'shortnocolor:无颜色简洁日志' \
  'filelog:显示文件级详细改动' \
  'recent-branches:最近 15 个活跃分支' \
  'a:添加文件到暂存区' \
  'chunkyadd:交互式选择改动块' \
  'ss:暂存当前改动' \
  'sl:列出所有暂存' \
  'sa:应用暂存' \
  'sd:删除暂存' \
  'snapshot:创建带时间戳的快照' \
  'snapshots:列出所有快照暂存' \
  'b:显示分支列表（含最新提交）' \
  'co:切换分支/文件' \
  'nb:创建并切换到新分支' \
  'c:快速提交' \
  'ca:添加所有改动并提交' \
  'ci:交互式提交' \
  'amend:修正上次提交' \
  'ammend:修正上次提交' \
  'd:查看工作区改动' \
  'dc:查看暂存区改动' \
  'last:查看最后一次提交的改动' \
  'dr:查看指定提交的改动' \
  'w:显示提交详情' \
  'ws:显示提交统计' \
  'r:显示远程仓库' \
  'ps:推送到远程' \
  'psa:推送所有分支' \
  'psd:删除远程分支' \
  'psb:推送并设置上游' \
  'pscb:推送当前分支' \
  'pl:拉取远程更新' \
  'fo:获取所有远程更新并清理' \
  'f:获取更新并 rebase 到 main' \
  'rb:智能 rebase' \
  'rbt:rebase 到 origin/main' \
  'rbr:交互式 rebase' \
  'rc:继续 rebase' \
  'rs:跳过当前提交' \
  'pro:为当前分支创建 PR' \
  'pr:推送分支并创建 PR' \
  'wl:列出所有工作树' \
  'wa:添加工作树' \
  'wf:删除工作树' \
  'cp:cherry-pick（保留原始引用）' \
  'ol:查看引用日志' \
  'fn:查看文件的逐行作者' \
  'fnr:查看指定行范围的作者' \
  'contributors:显示贡献者统计' \
  'mt:启动合并工具' \
  'svnr:SVN rebase' \
  'svnd:提交到 SVN' \
  'svnl:查看 SVN 日志'

# Enable better formatting for completions
zstyle ':completion:*:*:git:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:*:git:*' group-name ''

# Sort git commands: put aliases at the end
zstyle ':completion:*:*:git:*' tag-order 'main-porcelain-commands common-commands ancillary-manipulators ancillary-interrogators plumbing-manipulators plumbing-interrogators plumbing-sync-commands plumbing-sync-helper-commands plumbing-internal-helper-commands user-commands aliases'
