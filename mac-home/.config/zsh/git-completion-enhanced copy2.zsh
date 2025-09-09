#!/usr/bin/env zsh
# Enhanced git completion with alias support
# This file adds alias support to git completion similar to how git handles it

# First, ensure git completion is available
if (( $+commands[git] )); then
  # Generate git completion if not already done
  if ! typeset -f _git >/dev/null; then
    eval "$(git util completion zsh 2>/dev/null || true)"
  fi

  # Save the original _git_commands function
  if typeset -f _git_commands >/dev/null; then
    functions[_git_commands_original]=$functions[_git_commands]
  fi

  # Override _git_commands to include aliases with grouping
  _git_commands() {
    # Define essential aliases group (most commonly used)
    local -a essential_aliases
    local -a status_aliases
    local -a commit_aliases
    local -a rebase_aliases
    local -a bookmark_aliases
    local -a other_aliases

    # Call the original function first
    if typeset -f _git_commands_original >/dev/null; then
      _git_commands_original "$@"
    fi

    # Now add aliases with categorization
    local alias_line name value desc

    # Parse git aliases from config
    while IFS= read -r alias_line; do
      if [[ $alias_line =~ ^aliases\.([^[:space:]=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        name="${match[1]}"
        value="${match[2]}"

        # Clean up the value (remove brackets and quotes)
        value="${value//[\[\]]/}"
        value="${value//\'/}"

        # Create description based on alias name
        case $name in
          # 状态与日志
          s) desc="查看状态 -- alias for ${value}" ;;
          sf) desc="当前改动的 diff 摘要 -- alias for ${value}" ;;
          l) desc="查看日志 -- alias for ${value}" ;;
          lr) desc="查看指定版本集的日志 -- alias for ${value}" ;;
          ls) desc="查看 stash 日志 -- alias for ${value}" ;;
          lp) desc="查看私有提交 -- alias for ${value}" ;;
          lg) desc="查看所有提交 -- alias for ${value}" ;;
          default) desc="显示状态和最近日志 -- alias for ${value}" ;;

          # 仓库操作
          init) desc="初始化 Git 共存仓库 -- alias for ${value}" ;;
          cl) desc="克隆为 Git 共存仓库 -- alias for ${value}" ;;
          clg) desc="从 GitHub 克隆 HTTPS -- alias for ${value}" ;;
          clgp) desc="从 GitHub 克隆 SSH -- alias for ${value}" ;;
          clgu) desc="从 GitHub 克隆自己的仓库 -- alias for ${value}" ;;
          clsp) desc="从 Sourcehut 克隆 SSH -- alias for ${value}" ;;
          clsu) desc="从 Sourcehut 克隆自己的仓库 -- alias for ${value}" ;;

          # 差异
          d) desc="查看当前改动 -- alias for ${value}" ;;
          dr) desc="查看指定版本的改动 -- alias for ${value}" ;;

          # 创建新提交
          n) desc="创建新提交 -- alias for ${value}" ;;
          nm) desc="创建新提交并设置消息 -- alias for ${value}" ;;
          nt) desc="从 trunk 创建新提交 -- alias for ${value}" ;;
          ntm) desc="从 trunk 创建新提交并设置消息 -- alias for ${value}" ;;
          na) desc="在指定提交后插入 -- alias for ${value}" ;;
          nae) desc="在当前提交后插入 -- alias for ${value}" ;;
          naem) desc="在当前提交后插入并设置消息 -- alias for ${value}" ;;
          nb) desc="在指定提交前插入 -- alias for ${value}" ;;
          nbe) desc="在当前提交前插入 -- alias for ${value}" ;;
          nbem) desc="在当前提交前插入并设置消息 -- alias for ${value}" ;;

          # 描述与提交
          de) desc="编辑提交描述 -- alias for ${value}" ;;
          dem) desc="设置提交描述 -- alias for ${value}" ;;
          ci) desc="交互式提交 -- alias for ${value}" ;;
          cm) desc="快速提交 -- alias for ${value}" ;;
          cim) desc="交互式快速提交 -- alias for ${value}" ;;

          # 查看
          w) desc="显示提交详情 -- alias for ${value}" ;;
          ws) desc="显示提交统计 -- alias for ${value}" ;;

          # 编辑与导航
          e) desc="编辑提交 -- alias for ${value}" ;;
          eh) desc="编辑当前提交链的所有头部 -- alias for ${value}" ;;
          ep) desc="编辑前一个提交 -- alias for ${value}" ;;
          epc) desc="编辑前一个冲突提交 -- alias for ${value}" ;;
          en) desc="编辑下一个提交 -- alias for ${value}" ;;
          enc) desc="编辑下一个冲突提交 -- alias for ${value}" ;;

          # 放弃
          ad) desc="放弃提交 -- alias for ${value}" ;;
          adb) desc="放弃但保留书签 -- alias for ${value}" ;;
          adk) desc="放弃但保留书签并恢复后代 -- alias for ${value}" ;;

          # 拆分与合并
          sp) desc="交互式拆分提交 -- alias for ${value}" ;;
          spr) desc="拆分指定提交 -- alias for ${value}" ;;
          spp) desc="并行拆分 -- alias for ${value}" ;;
          sppr) desc="并行拆分指定提交 -- alias for ${value}" ;;
          sq) desc="交互式合并到父提交 -- alias for ${value}" ;;
          sqa) desc="自动合并到父提交 -- alias for ${value}" ;;
          sqt) desc="交互式合并到指定提交 -- alias for ${value}" ;;
          sqat) desc="自动合并到指定提交 -- alias for ${value}" ;;
          sqf) desc="交互式从指定提交合并 -- alias for ${value}" ;;
          sqaf) desc="自动从指定提交合并 -- alias for ${value}" ;;
          sqr) desc="交互式合并指定提交 -- alias for ${value}" ;;
          sqar) desc="自动合并指定提交 -- alias for ${value}" ;;

          # Rebase
          rb) desc="基础 rebase -- alias for ${value}" ;;
          rba) desc="rebase 到指定提交之后 -- alias for ${value}" ;;
          rbb) desc="rebase 到指定提交之前 -- alias for ${value}" ;;
          rbd) desc="rebase 到指定目标 -- alias for ${value}" ;;
          rbt) desc="rebase 到 trunk -- alias for ${value}" ;;
          rbtb) desc="将分支 rebase 到 trunk -- alias for ${value}" ;;
          rbtr) desc="将指定提交 rebase 到 trunk -- alias for ${value}" ;;
          rbtw) desc="将当前提交链 rebase 到 trunk -- alias for ${value}" ;;
          rbte) desc="将当前提交 rebase 到 trunk -- alias for ${value}" ;;
          rbta) desc="将所有可变头部 rebase 到 trunk -- alias for ${value}" ;;
          rbts) desc="从指定源 rebase 到 trunk -- alias for ${value}" ;;
          rbtse) desc="从当前提交 rebase 到 trunk -- alias for ${value}" ;;
          rbe) desc="rebase 到当前提交 -- alias for ${value}" ;;
          rbeb) desc="将分支 rebase 到当前 -- alias for ${value}" ;;
          rber) desc="将指定提交 rebase 到当前 -- alias for ${value}" ;;
          rbes) desc="从指定源 rebase 到当前 -- alias for ${value}" ;;
          rbr) desc="rebase 指定提交 -- alias for ${value}" ;;
          rbrb) desc="rebase 分支 -- alias for ${value}" ;;
          rbrw) desc="rebase 当前提交链 -- alias for ${value}" ;;
          rbrwd) desc="将当前提交链 rebase 到指定目标 -- alias for ${value}" ;;
          rbrwa) desc="将当前提交链 rebase 到指定提交之后 -- alias for ${value}" ;;
          rbrwb) desc="将当前提交链 rebase 到指定提交之前 -- alias for ${value}" ;;
          rbre) desc="rebase 当前提交 -- alias for ${value}" ;;
          rbred) desc="将当前提交 rebase 到指定目标 -- alias for ${value}" ;;
          rbrea) desc="将当前提交 rebase 到指定提交之后 -- alias for ${value}" ;;
          rbreb) desc="将当前提交 rebase 到指定提交之前 -- alias for ${value}" ;;
          rbs) desc="从指定源开始 rebase -- alias for ${value}" ;;
          rbse) desc="从当前提交开始 rebase -- alias for ${value}" ;;
          rbsed) desc="从当前 rebase 到指定目标 -- alias for ${value}" ;;
          rbsea) desc="从当前 rebase 到指定提交之后 -- alias for ${value}" ;;
          rbseb) desc="从当前 rebase 到指定提交之前 -- alias for ${value}" ;;

          # Absorb
          ab) desc="自动吸收改动 -- alias for ${value}" ;;
          abf) desc="从指定提交开始吸收 -- alias for ${value}" ;;

          # 恢复
          re) desc="恢复文件 -- alias for ${value}" ;;

          # 书签管理
          bd) desc="删除书签 -- alias for ${value}" ;;
          bf) desc="忘记书签 -- alias for ${value}" ;;
          bl) desc="列出所有书签 -- alias for ${value}" ;;
          blr) desc="列出指定版本的书签 -- alias for ${value}" ;;
          blrw) desc="列出当前提交链的书签 -- alias for ${value}" ;;
          blrb) desc="列出当前分支的书签 -- alias for ${value}" ;;
          bmw) desc="移动当前提交链的书签 -- alias for ${value}" ;;
          bmb) desc="移动当前分支的书签 -- alias for ${value}" ;;
          br) desc="重命名书签 -- alias for ${value}" ;;
          bs) desc="设置书签 -- alias for ${value}" ;;
          bsr) desc="设置书签到指定提交 -- alias for ${value}" ;;
          bst) desc="设置书签到 trunk -- alias for ${value}" ;;
          bt) desc="跟踪远程书签 -- alias for ${value}" ;;
          bu) desc="取消跟踪远程书签 -- alias for ${value}" ;;

          # Git 集成
          f) desc="获取更新并 rebase -- alias for ${value}" ;;
          fw) desc="监视 PR 检查后同步 -- alias for ${value}" ;;
          fo) desc="获取所有远程更新 -- alias for ${value}" ;;
          fa) desc="获取并 rebase 所有 -- alias for ${value}" ;;
          faw) desc="监视 PR 检查后同步所有分支 -- alias for ${value}" ;;
          ps) desc="推送到远程 -- alias for ${value}" ;;
          psb) desc="推送书签 -- alias for ${value}" ;;
          psc) desc="推送指定提交 -- alias for ${value}" ;;
          pscw) desc="推送当前提交链 -- alias for ${value}" ;;
          pscb) desc="推送当前分支 -- alias for ${value}" ;;
          psca) desc="推送所有可见头部 -- alias for ${value}" ;;
          psa) desc="推送所有 -- alias for ${value}" ;;
          psd) desc="推送删除 -- alias for ${value}" ;;
          psm) desc="推送到 main -- alias for ${value}" ;;
          psms) desc="推送到 master -- alias for ${value}" ;;

          # PR
          pro) desc="为当前分支创建 PR -- alias for ${value}" ;;
          pr) desc="推送并创建 PR -- alias for ${value}" ;;
          prow) desc="为当前提交链创建 PR -- alias for ${value}" ;;
          prw) desc="推送当前提交链并创建 PR -- alias for ${value}" ;;

          # 操作日志
          ol) desc="查看操作日志 -- alias for ${value}" ;;
          or) desc="恢复到指定操作 -- alias for ${value}" ;;
          ow) desc="显示操作详情 -- alias for ${value}" ;;
          owp) desc="显示操作的改动 -- alias for ${value}" ;;

          # 文件操作
          fn) desc="查看文件注释 -- alias for ${value}" ;;
          fnr) desc="查看指定版本的文件注释 -- alias for ${value}" ;;
          ft) desc="跟踪文件 -- alias for ${value}" ;;
          fu) desc="取消跟踪文件 -- alias for ${value}" ;;

          # 工作区
          wl) desc="列出工作区 -- alias for ${value}" ;;
          wa) desc="添加工作区 -- alias for ${value}" ;;
          wa1) desc="添加预定义工作区 1 -- alias for ${value}" ;;
          wa2) desc="添加预定义工作区 2 -- alias for ${value}" ;;
          wa3) desc="添加预定义工作区 3 -- alias for ${value}" ;;
          wo1) desc="切换到工作区 1 -- alias for ${value}" ;;
          wo2) desc="切换到工作区 2 -- alias for ${value}" ;;
          wo3) desc="切换到工作区 3 -- alias for ${value}" ;;
          wf) desc="忘记工作区 -- alias for ${value}" ;;
          wf1) desc="忘记工作区 1 -- alias for ${value}" ;;
          wf2) desc="忘记工作区 2 -- alias for ${value}" ;;
          wf3) desc="忘记工作区 3 -- alias for ${value}" ;;
          wr) desc="重命名工作区 -- alias for ${value}" ;;

          # UI
          ui) desc="启动 gitui -- alias for ${value}" ;;

          # Default case
          *) desc="alias for ${value}" ;;
        esac

        # Categorize the alias more logically
        case $name in
          # Essential (most commonly used single-letter)
          s|l|d|n|e|w|f) essential_aliases+=("${name}:${desc}") ;;

          # Status, log and history
          sf|lg|lp|lr|ls|default|ol|or|ow|owp) status_aliases+=("${name}:${desc}") ;;

          # Creating and editing commits
          ci|cm|cim|de|dem|nm|nt|ntm|na|nae|naem|nb|nbe|nbem|ad|adb|adk|sp|spp|sppr|spr|sq|sqa|sqt|sqat|sqf|sqaf|sqr|sqar) commit_aliases+=("${name}:${desc}") ;;

          # Navigation
          ep|epc|en|enc|eh) commit_aliases+=("${name}:${desc}") ;;

          # Rebase operations (all rb* commands)
          rb*) rebase_aliases+=("${name}:${desc}") ;;

          # Bookmark and branch management
          b[dflrstu]*|bmw|bmb) bookmark_aliases+=("${name}:${desc}") ;;

          # Git integration (push, pull, fetch)
          ps*|pr*|fo|fa|faw|fw|cl*|init) other_aliases+=("${name}:${desc}") ;;

          # File and workspace operations
          fn*|ft|fu|re|wa*|wf*|wl|wo*|wr|ab|abf|ui) other_aliases+=("${name}:${desc}") ;;

          # Everything else
          *) other_aliases+=("${name}:${desc}") ;;
        esac
      fi
    done < <(git config list  2>/dev/null | grep '^aliase\.')

    # Add aliases to completion with groups
    # if (( ${#essential_aliases} > 0 )); then
    #   _describe -t essential-aliases '核心命令 (Essential)' essential_aliases "$@"
    # fi
    # if (( ${#status_aliases} > 0 )); then
    #   _describe -t status-aliases '状态/日志/历史 (Status/Log)' status_aliases "$@"
    # fi
    # if (( ${#commit_aliases} > 0 )); then
    #   _describe -t commit-aliases '提交编辑 (Commit/Edit)' commit_aliases "$@"
    # fi
    # if (( ${#rebase_aliases} > 0 )); then
    #   _describe -t rebase-aliases 'Rebase 操作' rebase_aliases "$@"
    # fi
    # if (( ${#bookmark_aliases} > 0 )); then
    #   _describe -t bookmark-aliases '书签管理 (Bookmarks)' bookmark_aliases "$@"
    # fi
    # if (( ${#other_aliases} > 0 )); then
    #   _describe -t other-aliases '其他操作 (Git/File/Workspace)' other_aliases "$@"
    # fi
  }
fi




# Enable better formatting for completions
zstyle ':completion:*:*:git:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:*:git:*' group-name ''

# Sort git commands: put aliases at the end
zstyle ':completion:*:*:git:*' tag-order 'main-porcelain-commands common-commands ancillary-manipulators ancillary-interrogators plumbing-manipulators plumbing-interrogators plumbing-sync-commands plumbing-sync-helper-commands plumbing-internal-helper-commands user-commands aliases'



# # Enable better formatting
# zstyle ':completion:*:*:git:*' verbose yes
# zstyle ':completion:*:*:git:*' group-name ''
# zstyle ':completion:*:descriptions' format '%B%d%b'

# # Define command group order for git
# zstyle ':completion:*:*:git:*' group-order \
#   'essential-aliases' \
#   'commands' \
#   'status-aliases' \
#   'commit-aliases' \
#   'rebase-aliases' \
#   'bookmark-aliases' \
#   'other-aliases'

# # Make the essential commands stand out
# zstyle ':completion:*:*:git:*:essential-aliases' list-colors '=*=1;32'
# zstyle ':completion:*:*:git:*:commands' list-colors '=*=0;37'
