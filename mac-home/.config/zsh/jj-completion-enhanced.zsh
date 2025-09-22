#!/usr/bin/env zsh
# Enhanced JJ completion with alias support
# This file adds alias support to jj completion similar to how git handles it

# First, ensure jj completion is available
if (( $+commands[jj] )); then
  # Generate jj completion if not already done
  if ! typeset -f _jj >/dev/null; then
    eval "$(jj util completion zsh 2>/dev/null || true)"
  fi

  # Save the original _jj_commands function
  if typeset -f _jj_commands >/dev/null; then
    functions[_jj_commands_original]=$functions[_jj_commands]
  fi

  # Override _jj_commands to include aliases with grouping
  _jj_commands() {
    # Define alias groups (compact to 8 groups)
    local -a essential_aliases
    local -a statuslog_aliases
    local -a viewdiff_aliases
    local -a commitedit_aliases
    local -a rebase_aliases
    local -a bookmark_aliases
    local -a remoterepo_aliases
    local -a workspacefile_aliases

    # Build and add aliases with categorization first (so commands can be last)
    local alias_line name value desc

    # Parse jj aliases from config
    while IFS= read -r alias_line; do
      if [[ $alias_line =~ ^aliases\.([^[:space:]=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        name="${match[1]}"
        value="${match[2]}"

        # Clean up the value (remove brackets and quotes)
        value="${value//[\[\]]/}"
        value="${value//\'/}"
        value="${value//\,/}"

        # Create description based on alias name
        case $name in
          # 状态与日志
          s) desc="查看状态：${value}" ;;
          sf) desc="当前改动的 diff 摘要：${value}" ;;
          l) desc="查看日志：${value}" ;;
          lr) desc="查看指定版本集的日志：${value}" ;;
          ls) desc="查看 stash 日志：${value}" ;;
          lp) desc="查看私有提交：${value}" ;;
          lg) desc="查看所有提交：${value}" ;;
          default) desc="显示状态和最近日志：${value}" ;;

          # 仓库操作
          init) desc="初始化 Git 共存仓库：${value}" ;;
          cl) desc="克隆为 Git 共存仓库：${value}" ;;
          clg) desc="从 GitHub 克隆 HTTPS：${value}" ;;
          clgp) desc="从 GitHub 克隆 SSH：${value}" ;;
          clgu) desc="从 GitHub 克隆自己的仓库：${value}" ;;
          clsp) desc="从 Sourcehut 克隆 SSH：${value}" ;;
          clsu) desc="从 Sourcehut 克隆自己的仓库：${value}" ;;

          # 差异
          d) desc="查看当前改动：${value}" ;;
          dr) desc="查看指定版本的改动：${value}" ;;

          # 创建新提交
          n) desc="创建新提交：${value}" ;;
          nm) desc="创建新提交并设置消息：${value}" ;;
          nt) desc="从 trunk 创建新提交：${value}" ;;
          ntm) desc="从 trunk 创建新提交并设置消息：${value}" ;;
          na) desc="在指定提交后插入：${value}" ;;
          nae) desc="在当前提交后插入：${value}" ;;
          naem) desc="在当前提交后插入并设置消息：${value}" ;;
          nb) desc="在指定提交前插入：${value}" ;;
          nbe) desc="在当前提交前插入：${value}" ;;
          nbem) desc="在当前提交前插入并设置消息：${value}" ;;

          # 描述与提交
          de) desc="编辑提交描述：${value}" ;;
          dem) desc="设置提交描述：${value}" ;;
          ci) desc="交互式提交：${value}" ;;
          cm) desc="快速提交：${value}" ;;
          cim) desc="交互式快速提交：${value}" ;;

          # 查看
          w) desc="显示提交详情：${value}" ;;
          ws) desc="显示提交统计：${value}" ;;

          # 编辑与导航
          e) desc="编辑提交：${value}" ;;
          eh) desc="编辑当前提交链的所有头部：${value}" ;;
          ep) desc="编辑前一个提交：${value}" ;;
          epc) desc="编辑前一个冲突提交：${value}" ;;
          en) desc="编辑下一个提交：${value}" ;;
          enc) desc="编辑下一个冲突提交：${value}" ;;

          # 放弃
          ad) desc="放弃提交：${value}" ;;
          adb) desc="放弃但保留书签：${value}" ;;
          adk) desc="放弃但保留书签并恢复后代：${value}" ;;

          # 拆分与合并
          sp) desc="交互式拆分提交：${value}" ;;
          spr) desc="拆分指定提交：${value}" ;;
          spp) desc="并行拆分：${value}" ;;
          sppr) desc="并行拆分指定提交：${value}" ;;
          sq) desc="交互式合并到父提交：${value}" ;;
          sqa) desc="自动合并到父提交：${value}" ;;
          sqt) desc="交互式合并到指定提交：${value}" ;;
          sqat) desc="自动合并到指定提交：${value}" ;;
          sqf) desc="交互式从指定提交合并：${value}" ;;
          sqaf) desc="自动从指定提交合并：${value}" ;;
          sqr) desc="交互式合并指定提交：${value}" ;;
          sqar) desc="自动合并指定提交：${value}" ;;

          # Rebase
          rb) desc="基础 rebase：${value}" ;;
          rba) desc="rebase 到指定提交之后：${value}" ;;
          rbb) desc="rebase 到指定提交之前：${value}" ;;
          rbd) desc="rebase 到指定目标：${value}" ;;
          rbt) desc="rebase 到 trunk：${value}" ;;
          rbtb) desc="将分支 rebase 到 trunk：${value}" ;;
          rbtr) desc="将指定提交 rebase 到 trunk：${value}" ;;
          rbtw) desc="将当前提交链 rebase 到 trunk：${value}" ;;
          rbte) desc="将当前提交 rebase 到 trunk：${value}" ;;
          rbta) desc="将所有可变头部 rebase 到 trunk：${value}" ;;
          rbts) desc="从指定源 rebase 到 trunk：${value}" ;;
          rbtse) desc="从当前提交 rebase 到 trunk：${value}" ;;
          rbe) desc="rebase 到当前提交：${value}" ;;
          rbeb) desc="将分支 rebase 到当前：${value}" ;;
          rber) desc="将指定提交 rebase 到当前：${value}" ;;
          rbes) desc="从指定源 rebase 到当前：${value}" ;;
          rbr) desc="rebase 指定提交：${value}" ;;
          rbrb) desc="rebase 分支：${value}" ;;
          rbrw) desc="rebase 当前提交链：${value}" ;;
          rbrwd) desc="将当前提交链 rebase 到指定目标：${value}" ;;
          rbrwa) desc="将当前提交链 rebase 到指定提交之后：${value}" ;;
          rbrwb) desc="将当前提交链 rebase 到指定提交之前：${value}" ;;
          rbre) desc="rebase 当前提交：${value}" ;;
          rbred) desc="将当前提交 rebase 到指定目标：${value}" ;;
          rbrea) desc="将当前提交 rebase 到指定提交之后：${value}" ;;
          rbreb) desc="将当前提交 rebase 到指定提交之前：${value}" ;;
          rbs) desc="从指定源开始 rebase：${value}" ;;
          rbse) desc="从当前提交开始 rebase：${value}" ;;
          rbsed) desc="从当前 rebase 到指定目标：${value}" ;;
          rbsea) desc="从当前 rebase 到指定提交之后：${value}" ;;
          rbseb) desc="从当前 rebase 到指定提交之前：${value}" ;;

          # Absorb
          ab) desc="自动吸收改动：${value}" ;;
          abf) desc="从指定提交开始吸收：${value}" ;;

          # 恢复
          re) desc="恢复文件：${value}" ;;

          # 书签管理
          bd) desc="删除书签：${value}" ;;
          bf) desc="忘记书签：${value}" ;;
          bl) desc="列出所有书签：${value}" ;;
          blr) desc="列出指定版本的书签：${value}" ;;
          blrw) desc="列出当前提交链的书签：${value}" ;;
          blrb) desc="列出当前分支的书签：${value}" ;;
          bmw) desc="移动当前提交链的书签：${value}" ;;
          bmb) desc="移动当前分支的书签：${value}" ;;
          br) desc="重命名书签：${value}" ;;
          bs) desc="设置书签：${value}" ;;
          bsr) desc="设置书签到指定提交：${value}" ;;
          bst) desc="设置书签到 trunk：${value}" ;;
          bt) desc="跟踪远程书签：${value}" ;;
          bu) desc="取消跟踪远程书签：${value}" ;;

          # Git 集成
          f) desc="获取更新并 rebase：${value}" ;;
          fw) desc="监视 PR 检查后同步：${value}" ;;
          fo) desc="获取所有远程更新：${value}" ;;
          fa) desc="获取并 rebase 所有：${value}" ;;
          faw) desc="监视 PR 检查后同步所有分支：${value}" ;;
          ps) desc="推送到远程：${value}" ;;
          psb) desc="推送书签：${value}" ;;
          psc) desc="推送指定提交：${value}" ;;
          pscw) desc="推送当前提交链：${value}" ;;
          pscb) desc="推送当前分支：${value}" ;;
          psca) desc="推送所有可见头部：${value}" ;;
          psa) desc="推送所有：${value}" ;;
          psd) desc="推送删除：${value}" ;;
          psm) desc="推送到 main：${value}" ;;
          psms) desc="推送到 master：${value}" ;;

          # PR
          pro) desc="为当前分支创建 PR：${value}" ;;
          pr) desc="推送并创建 PR：${value}" ;;
          prow) desc="为当前提交链创建 PR：${value}" ;;
          prw) desc="推送当前提交链并创建 PR：${value}" ;;

          # 操作日志
          ol) desc="查看操作日志：${value}" ;;
          or) desc="恢复到指定操作：${value}" ;;
          ow) desc="显示操作详情：${value}" ;;
          owp) desc="显示操作的改动：${value}" ;;

          # 文件操作
          fn) desc="查看文件注释：${value}" ;;
          fnr) desc="查看指定版本的文件注释：${value}" ;;
          ft) desc="跟踪文件：${value}" ;;
          fu) desc="取消跟踪文件：${value}" ;;

          # 工作区
          wl) desc="列出工作区：${value}" ;;
          wa) desc="添加工作区：${value}" ;;
          wa1) desc="添加预定义工作区 1：${value}" ;;
          wa2) desc="添加预定义工作区 2：${value}" ;;
          wa3) desc="添加预定义工作区 3：${value}" ;;
          wo1) desc="切换到工作区 1：${value}" ;;
          wo2) desc="切换到工作区 2：${value}" ;;
          wo3) desc="切换到工作区 3：${value}" ;;
          wf) desc="忘记工作区：${value}" ;;
          wf1) desc="忘记工作区 1：${value}" ;;
          wf2) desc="忘记工作区 2：${value}" ;;
          wf3) desc="忘记工作区 3：${value}" ;;
          wr) desc="重命名工作区：${value}" ;;

          # UI
          ui) desc="启动 jjui：${value}" ;;

          # Default case
          *) desc="alias for ${value}" ;;
        esac

        # Categorize the alias more logically (8 groups)
        case $name in
          # Essential (keep minimal)
          s|l) essential_aliases+=("${name}:${desc}") ;;

          # Status & Log (include Ops: ol/or/ow/owp)
          sf|lg|lp|lr|ls|default|ol|or|ow|owp) statuslog_aliases+=("${name}:${desc}") ;;

          # View & Diff
          w|ws|d|dr) viewdiff_aliases+=("${name}:${desc}") ;;

          # Commit & Edit (incl. split/squash/abandon/navigate/absorb)
          ci|cm|cim|de|dem|nm|nt|ntm|na|nae|naem|nb|nbe|nbem|ad|adb|adk|sp|spp|sppr|spr|sq|sqa|sqt|sqat|sqf|sqaf|sqr|sqar|ep|epc|en|enc|eh|ab|abf) commitedit_aliases+=("${name}:${desc}") ;;

          # Rebase
          rb*) rebase_aliases+=("${name}:${desc}") ;;

          # Bookmarks & Branches
          b[dflrstu]*|bmw|bmb|br|bs|bsr|bst|bt|bu) bookmark_aliases+=("${name}:${desc}") ;;

          # Remote & Repo (push/fetch/PR + init/clone)
          ps*|pr*|pro|prow|prw|fo|fa|faw|fw|init|cl|clg|clgp|clgu|clsp|clsu) remoterepo_aliases+=("${name}:${desc}") ;;

          # Workspace & Files (workspaces + file operations + ui)
          wl|wa*|wf*|wo*|wr|fn*|ft|fu|re|ui) workspacefile_aliases+=("${name}:${desc}") ;;

          # Fallbacks → put into Commit/Edit to avoid extra groups
          *) commitedit_aliases+=("${name}:${desc}") ;;
        esac
      fi
    done < <(jj config list --user 2>/dev/null | grep '^aliases\.')

    # Sort each group by alias name for stable ordering, then add to completion
    (( ${#essential_aliases}     )) && essential_aliases=(${(o)essential_aliases})
    (( ${#statuslog_aliases}     )) && statuslog_aliases=(${(o)statuslog_aliases})
    (( ${#viewdiff_aliases}      )) && viewdiff_aliases=(${(o)viewdiff_aliases})
    (( ${#commitedit_aliases}    )) && commitedit_aliases=(${(o)commitedit_aliases})
    (( ${#rebase_aliases}        )) && rebase_aliases=(${(o)rebase_aliases})
    (( ${#bookmark_aliases}      )) && bookmark_aliases=(${(o)bookmark_aliases})
    (( ${#remoterepo_aliases}    )) && remoterepo_aliases=(${(o)remoterepo_aliases})
    (( ${#workspacefile_aliases} )) && workspacefile_aliases=(${(o)workspacefile_aliases})

    # Add aliases to completion with 8 groups
    (( ${#essential_aliases}     )) && _describe -t essential-aliases       'Core'                essential_aliases "$@"
    (( ${#statuslog_aliases}     )) && _describe -t statuslog-aliases       'Status/Log/Ops'      statuslog_aliases "$@"
    (( ${#viewdiff_aliases}      )) && _describe -t viewdiff-aliases        'View/Diff'           viewdiff_aliases "$@"
    (( ${#commitedit_aliases}    )) && _describe -t commit-edit-aliases     'Commit/Edit'         commitedit_aliases "$@"
    (( ${#rebase_aliases}        )) && _describe -t rebase-aliases          'Rebase'              rebase_aliases "$@"
    (( ${#bookmark_aliases}      )) && _describe -t bookmark-aliases        'Bookmarks'           bookmark_aliases "$@"
    (( ${#remoterepo_aliases}    )) && _describe -t remote-repo-aliases     'Remote/Repo/PR'      remoterepo_aliases "$@"
    (( ${#workspacefile_aliases} )) && _describe -t workspace-file-aliases  'Workspace/File/UI'   workspacefile_aliases "$@"

    # Finally, call the original provider to emit the built-in commands group(s)
    if typeset -f _jj_commands_original >/dev/null; then
      _jj_commands_original "$@"
    fi
  }
fi

# Enable better formatting
zstyle ':completion:*:*:jj:*' verbose yes
# Use plain text (no escapes) so fzf-tab can read group headers
zstyle ':completion:*:descriptions' format '[%d]'

# Define tag and group order for jj (commands last)
# Avoid restricting results to a single tag; rely on group-order only
zstyle ':completion:*:*:jj:*' group-order \
  'essential-aliases' \
  'statuslog-aliases' \
  'viewdiff-aliases' \
  'commit-edit-aliases' \
  'rebase-aliases' \
  'bookmark-aliases' \
  'remote-repo-aliases' \
  'workspace-file-aliases' \
  'commands' \
  'command'

# fzf-tab group order for jj
zstyle ':fzf-tab:complete:jj:*' descriptions yes
zstyle ':fzf-tab:complete:jj:*' show-group yes
zstyle ':fzf-tab:complete:jj:*' group-order \
  'essential-aliases' 'statuslog-aliases' 'viewdiff-aliases' 'commit-edit-aliases' \
  'rebase-aliases' 'bookmark-aliases' 'remote-repo-aliases' 'workspace-file-aliases' \
  'commands' 'command'

# Make the essential commands stand out
zstyle ':completion:*:*:jj:*:essential-aliases' list-colors '=*=1;32'
zstyle ':completion:*:*:jj:*:commands' list-colors '=*=0;37'
