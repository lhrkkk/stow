#!/usr/bin/env zsh
# Enhanced Git completion with dynamic alias support (similar to JJ)
# - Autoloads _git if needed
# - Reads aliases from git config and exposes them to completion with descriptions

# Marker env for quick verification in shell: echo $GIT_COMPLETION_ENHANCED
typeset -g GIT_COMPLETION_ENHANCED=1

if (( $+commands[git] )); then
  # Ensure git completion is available if not yet autoloaded
  if ! typeset -f _git >/dev/null; then
    autoload -Uz _git 2>/dev/null || true
  fi

  # Build user-commands list from git aliases (with category labels)
  __git_build_user_commands() {
    local -a user_cmds
    local raw key val name rec

    # Collect aliases from the effective config (global context is enough for user aliases)
    # Use NUL-separated pairs: key\nvalue\0...
    raw=$(git config -z --get-regexp '^alias\.' 2>/dev/null)
    [[ -z $raw ]] && return 0

    # Known alias descriptions (override when available)
    local -A desc_map
    desc_map=()
    # Init/clone
    desc_map[init]='初始化仓库（默认分支 main）'
    desc_map[cl]='克隆仓库'
    desc_map[clg]='从 GitHub 克隆（HTTPS）'
    desc_map[clgp]='从 GitHub 克隆（SSH）'
    desc_map[clgu]='从 GitHub 克隆自己的仓库'

    # Status/log
    desc_map[s]='查看状态'
    desc_map[st]='查看状态'
    desc_map[stat]='查看状态'
    desc_map[sf]='简洁状态 + diff 统计'
    desc_map[l]='简洁图形化日志'
    desc_map[lg]='美化图形化日志（所有分支）'
    desc_map[default]='显示状态和最近日志'
    desc_map[filelog]='显示文件级详细改动'
    desc_map[changes]='显示提交的文件变化'
    desc_map[short]='简洁格式日志'
    desc_map[simple]='极简日志（仅提交信息）'
    desc_map[shortnocolor]='无颜色简洁日志'

    # Stash
    desc_map[ss]='暂存当前改动'
    desc_map[sl]='列出所有暂存'
    desc_map[sa]='应用暂存'
    desc_map[sd]='删除暂存'
    desc_map[snapshot]='创建带时间戳的快照'
    desc_map[snapshots]='列出所有快照暂存'

    # Branch/checkout
    desc_map[b]='显示分支列表（含最新提交）'
    desc_map[co]='切换分支/文件'
    desc_map[nb]='创建并切换到新分支'
    desc_map[recent-branches]='最近活跃分支'

    # Commit
    desc_map[c]='快速提交'
    desc_map[ca]='添加所有改动并提交'
    desc_map[ci]='交互式提交'
    desc_map[amend]='修正上次提交'
    desc_map[ammend]='修正上次提交'

    # Diff/show
    desc_map[d]='查看工作区改动'
    desc_map[dc]='查看暂存区改动'
    desc_map[last]='查看最后一次提交的改动'
    desc_map[dr]='查看指定提交的改动'
    desc_map[w]='显示提交详情'
    desc_map[ws]='显示提交统计'

    # Remote/push/pull
    desc_map[r]='显示远程仓库'
    desc_map[ps]='推送到远程'
    desc_map[psa]='推送所有分支'
    desc_map[psd]='删除远程分支'
    desc_map[psb]='推送并设置上游'
    desc_map[pscb]='推送当前分支'
    desc_map[pl]='拉取远程更新'
    desc_map[fo]='获取所有远程并清理'
    desc_map[f]='获取更新并 rebase 到 main'

    # Rebase
    desc_map[rb]='rebase（保留合并）'
    desc_map[rbt]='rebase 到 origin/main'
    desc_map[rbr]='交互式 rebase'
    desc_map[rc]='继续 rebase'
    desc_map[rs]='跳过当前提交'

    # PR (GitHub CLI)
    desc_map[pro]='为当前分支创建 PR'
    desc_map[pr]='推送分支并创建 PR'

    # Worktree/reflog/blame
    desc_map[wl]='列出所有工作树'
    desc_map[wa]='添加工作树'
    desc_map[wf]='删除工作树'
    desc_map[ol]='查看引用日志'
    desc_map[fn]='查看文件逐行作者'
    desc_map[fnr]='查看指定行范围作者'

    # Others
    desc_map[contributors]='显示贡献者统计'
    desc_map[mt]='启动合并工具'

    # Git Town
    desc_map[append]='[Town] 在当前分支后追加新分支'
    desc_map[hack]='[Town] 创建新的 feature 分支'
    desc_map[kill]='[Town] 删除当前分支并切回父分支'
    desc_map[new-pull-request]='[Town] 创建 PR'
    desc_map[prepend]='[Town] 在当前分支前插入新分支'
    desc_map[prune-branches]='[Town] 清理已合并的分支'
    desc_map[rename-branch]='[Town] 重命名当前分支'
    desc_map[repo]='[Town] 在浏览器中打开仓库'
    desc_map[ship]='[Town] 合并当前分支到主分支'
    desc_map[sync]='[Town] 同步当前分支与远程'

    # Category mapping
    local -A cat_map; cat_map=()
    # 状态/日志
    for k in s st stat sf l lg default filelog changes short simple shortnocolor; do cat_map[$k]=status; done
    # 暂存/快照
    for k in ss sl sa sd snapshot snapshots; do cat_map[$k]=stash; done
    # 分支/切换
    for k in b co nb recent-branches; do cat_map[$k]=branch; done
    # 提交
    for k in c ca ci amend ammend; do cat_map[$k]=commit; done
    # 差异/查看
    for k in d dc last dr w ws; do cat_map[$k]=diff; done
    # 远程/推送/拉取
    for k in r ps psa psd psb pscb pl fo f; do cat_map[$k]=remote; done
    # Rebase
    for k in rb rbt rbr rc rs; do cat_map[$k]=rebase; done
    # PR
    for k in pro pr; do cat_map[$k]=pr; done
    # 工作树/引用日志/责备
    for k in wl wa wf ol fn fnr; do cat_map[$k]=worktree; done
    # 初始化/克隆
    for k in init cl clg clgp clgu; do cat_map[$k]=repo; done
    # Git Town
    for k in append hack kill new-pull-request prepend prune-branches rename-branch repo ship sync; do cat_map[$k]=town; done

    # Category labels (display)
    local -A cat_label
    cat_label=(
      status '状态/日志'
      stash '暂存/快照'
      branch '分支/切换'
      commit '提交'
      diff '差异/查看'
      remote '远程/推送/拉取'
      rebase 'Rebase'
      pr 'PR'
      worktree '工作树/日志/责备'
      repo '初始化/克隆'
      town 'Git Town'
      other '其他'
    )

    # Per-category buckets to preserve visual grouping order
    local -a _cat_order=(repo status stash branch commit diff remote rebase pr worktree town other)
    # One array per category (zsh does not support arrays as values of associative arrays)
    local -a \
      bucket_repo bucket_status bucket_stash bucket_branch bucket_commit \
      bucket_diff bucket_remote bucket_rebase bucket_pr bucket_worktree \
      bucket_town bucket_other

    # Split NUL-separated records safely in zsh
    local -a __records
    __records=(${(0)raw})
    for rec in ${__records[@]}; do
      # Each line is: key\nvalue
      key=${rec%%$'\n'*}
      val=${rec#*$'\n'}
      name=${key#alias.}

      # Strip surrounding quotes if any (keep simple to avoid parsing quirks)
      # Remove all straight double quotes just for description readability
      val=${val//\"/}

      # Build description with category label + friendly text + expansion
      local base_desc=${desc_map[$name]}
      [[ -z $base_desc ]] && base_desc="别名"
      local c=${cat_map[$name]:-other}
      local label=${cat_label[$c]:-其他}
      local desc="${label} — ${base_desc} - ${val}"
      # Append into its bucket without nameref (compat with older zsh)
      case $c in
        repo)      bucket_repo+=("${name}:${desc}") ;;
        status)    bucket_status+=("${name}:${desc}") ;;
        stash)     bucket_stash+=("${name}:${desc}") ;;
        branch)    bucket_branch+=("${name}:${desc}") ;;
        commit)    bucket_commit+=("${name}:${desc}") ;;
        diff)      bucket_diff+=("${name}:${desc}") ;;
        remote)    bucket_remote+=("${name}:${desc}") ;;
        rebase)    bucket_rebase+=("${name}:${desc}") ;;
        pr)        bucket_pr+=("${name}:${desc}") ;;
        worktree)  bucket_worktree+=("${name}:${desc}") ;;
        town)      bucket_town+=("${name}:${desc}") ;;
        *)         bucket_other+=("${name}:${desc}") ;;
      esac
    done

    # Flatten buckets in a deterministic category order
    local -a ordered
    local cat
    for cat in ${_cat_order[@]}; do
      case $cat in
        repo)      (( ${#bucket_repo[@]} ))      && ordered+=(${bucket_repo[@]}) ;;
        status)    (( ${#bucket_status[@]} ))    && ordered+=(${bucket_status[@]}) ;;
        stash)     (( ${#bucket_stash[@]} ))     && ordered+=(${bucket_stash[@]}) ;;
        branch)    (( ${#bucket_branch[@]} ))    && ordered+=(${bucket_branch[@]}) ;;
        commit)    (( ${#bucket_commit[@]} ))    && ordered+=(${bucket_commit[@]}) ;;
        diff)      (( ${#bucket_diff[@]} ))      && ordered+=(${bucket_diff[@]}) ;;
        remote)    (( ${#bucket_remote[@]} ))    && ordered+=(${bucket_remote[@]}) ;;
        rebase)    (( ${#bucket_rebase[@]} ))    && ordered+=(${bucket_rebase[@]}) ;;
        pr)        (( ${#bucket_pr[@]} ))        && ordered+=(${bucket_pr[@]}) ;;
        worktree)  (( ${#bucket_worktree[@]} ))  && ordered+=(${bucket_worktree[@]}) ;;
        town)      (( ${#bucket_town[@]} ))      && ordered+=(${bucket_town[@]}) ;;
        other)     (( ${#bucket_other[@]} ))     && ordered+=(${bucket_other[@]}) ;;
      esac
    done

    # Export globally for our alias provider
    typeset -g -a __git_uc_list \
      __git_bucket_repo __git_bucket_status __git_bucket_stash __git_bucket_branch \
      __git_bucket_commit __git_bucket_diff __git_bucket_remote __git_bucket_rebase \
      __git_bucket_pr __git_bucket_worktree __git_bucket_town __git_bucket_other
    __git_uc_list=("${ordered[@]}")
    __git_bucket_repo=("${bucket_repo[@]}")
    __git_bucket_status=("${bucket_status[@]}")
    __git_bucket_stash=("${bucket_stash[@]}")
    __git_bucket_branch=("${bucket_branch[@]}")
    __git_bucket_commit=("${bucket_commit[@]}")
    __git_bucket_diff=("${bucket_diff[@]}")
    __git_bucket_remote=("${bucket_remote[@]}")
    __git_bucket_rebase=("${bucket_rebase[@]}")
    __git_bucket_pr=("${bucket_pr[@]}")
    __git_bucket_worktree=("${bucket_worktree[@]}")
    __git_bucket_town=("${bucket_town[@]}")
    __git_bucket_other=("${bucket_other[@]}")
  }

  __git_build_user_commands
fi

__git_apply_styles() {
  # Keep completions grouped and consistent with system _git
  zstyle ':completion:*' list-grouped yes
  zstyle ':completion:*:*:git:*' verbose yes
  # Do not sort matches; preserve emission order across groups
  zstyle ':completion:*:*:git:*' sort false
  # Plain text descriptions so fzf-tab recognizes groups
  zstyle ':completion:*:descriptions' format '[%d]'
  # Only show our 8 alias groups (hide system commands entirely)
  zstyle ':completion:*:*:git:*' tag-order \
    'git8-essential' \
    'git8-statuslog' \
    'git8-viewdiff' \
    'git8-commitedit' \
    'git8-rebase' \
    'git8-branchworktree' \
    'git8-remotepr' \
    'git8-repoops'
  zstyle ':completion:*:*:git:*' group-order \
    'git8-essential' \
    'git8-statuslog' \
    'git8-viewdiff' \
    'git8-commitedit' \
    'git8-rebase' \
    'git8-branchworktree' \
    'git8-remotepr' \
    'git8-repoops'
}

__git_emit_ami_alias_groups() {
  emulate -L zsh
  __git_build_user_commands
  local -a __g8_essential __g8_statuslog __g8_viewdiff __g8_commitedit __g8_rebase __g8_branchworktree __g8_remotepr __g8_repoops
  local it name

  # Helpers to append pairs
  __append_all() { local -a src=("$@"); (( ${#src[@]} )) && eval "$1"; }

  # status -> essential(s,l) + statuslog(others)
  for it in ${__git_bucket_status[@]}; do
    name=${it%%:*}
    case $name in
      s|l) __g8_essential+=("$it") ;;
      *)   __g8_statuslog+=("$it") ;;
    esac
  done
  # diff/show -> viewdiff
  (( ${#__git_bucket_diff[@]} )) && __g8_viewdiff+=("${__git_bucket_diff[@]}")

  # commit + stash -> commitedit
  (( ${#__git_bucket_commit[@]} )) && __g8_commitedit+=("${__git_bucket_commit[@]}")
  (( ${#__git_bucket_stash[@]}  )) && __g8_commitedit+=("${__git_bucket_stash[@]}")

  # rebase
  (( ${#__git_bucket_rebase[@]} )) && __g8_rebase+=("${__git_bucket_rebase[@]}")

  # branch + worktree -> branchworktree (but move blame fn/fnr to viewdiff)
  (( ${#__git_bucket_branch[@]}   )) && __g8_branchworktree+=("${__git_bucket_branch[@]}")
  if (( ${#__git_bucket_worktree[@]} )); then
    local _wt
    for _wt in ${__git_bucket_worktree[@]}; do
      name=${_wt%%:*}
      case $name in
        fn|fnr) __g8_viewdiff+=("$_wt") ;;
        *)      __g8_branchworktree+=("$_wt") ;;
      esac
    done
  fi

  # remote + pr -> remotepr
  (( ${#__git_bucket_remote[@]} )) && __g8_remotepr+=("${__git_bucket_remote[@]}")
  (( ${#__git_bucket_pr[@]}     )) && __g8_remotepr+=("${__git_bucket_pr[@]}")

  # repo + town -> repoops
  (( ${#__git_bucket_repo[@]} )) && __g8_repoops+=("${__git_bucket_repo[@]}")
  (( ${#__git_bucket_town[@]} )) && __g8_repoops+=("${__git_bucket_town[@]}")

  # other -> re-route to closest groups
  for it in ${__git_bucket_other[@]}; do
    name=${it%%:*}
    case $name in
      ad|ads)                 __g8_viewdiff+=("$it") ;;
      a|chunkyadd|mt|cp)      __g8_commitedit+=("$it") ;;
      contributors)           __g8_statuslog+=("$it") ;;
      svnr|svnd|svnl)         __g8_repoops+=("$it") ;;
      *)                      __g8_commitedit+=("$it") ;;
    esac
  done

  (( ${#__g8_essential[@]}      )) && _describe -t git8-essential      '核心'                 __g8_essential
  (( ${#__g8_statuslog[@]}      )) && _describe -t git8-statuslog      '状态/日志'            __g8_statuslog
  (( ${#__g8_viewdiff[@]}       )) && _describe -t git8-viewdiff       '查看/差异'            __g8_viewdiff
  (( ${#__g8_commitedit[@]}     )) && _describe -t git8-commitedit     '提交/暂存'            __g8_commitedit
  (( ${#__g8_rebase[@]}         )) && _describe -t git8-rebase         'Rebase'               __g8_rebase
  (( ${#__g8_branchworktree[@]} )) && _describe -t git8-branchworktree '分支/工作树'          __g8_branchworktree
  (( ${#__g8_remotepr[@]}       )) && _describe -t git8-remotepr       '远程/推送/PR'          __g8_remotepr
  (( ${#__g8_repoops[@]}        )) && _describe -t git8-repoops        '仓库/协作'            __g8_repoops
}

__git_complete_with_aliases() {
  emulate -L zsh
  autoload -Uz _git 2>/dev/null || true
  # Ensure our overrides are loaded before any emission
  __git_load_and_override
  __git_apply_styles
  # Ensure fzf-tab shows descriptions and groups
  zstyle ':fzf-tab:complete:git:*' descriptions yes 2>/dev/null || true
  zstyle ':fzf-tab:complete:git:*' show-group yes 2>/dev/null || true
  _git
}

# Install wrapper mapping now and ensure it persists after compinit
compdef __git_complete_with_aliases=git 2>/dev/null || compdef __git_complete_with_aliases git 2>/dev/null || true
if [[ $- == *i* ]]; then
  autoload -Uz add-zsh-hook 2>/dev/null || true
  # 轻量兜底：每次 precmd 重新保证 git 的 compdef 指向我们
  __git_compdef_always() { compdef __git_complete_with_aliases=git }
  add-zsh-hook -Uz precmd __git_compdef_always 2>/dev/null || true
fi

# Load git's zsh wrapper (after compinit) and override its alias provider
__git_load_and_override() {
  # Load the wrapper script from fpath if not yet loaded
  if [[ $functions[_git] == *"autoload -X"* ]]; then
    local d _f
    for d in $fpath; do
      _f="$d/_git"
      [[ -r $_f ]] || continue
      builtin source "$_f"
      break
    done
  fi
  # Neutralize system alias providers (we inject aliases via _git_commands wrapper)
  __git_zsh_cmd_alias() { return 1 }
  __git_aliases() { return 1 }
  __git_extract_aliases() { aliases=() }

  # Override command list to prepend our alias groups in the same completion pass
  if typeset -f _git_commands >/dev/null; then
    functions[_git_commands_original]=$functions[_git_commands]
    _git_commands() {
      emulate -L zsh
      # Only emit our 8 alias groups (hide system commands)
      __git_emit_ami_alias_groups "$@"
      return 0
    }
  fi
  __git_apply_styles
}

# Our lazy-compinit integration hook calls this exactly once after compinit
__git_set_user_commands() {
  emulate -L zsh
  __git_build_user_commands
  local -a pairs newlist
  local it name desc
  pairs=( "${__git_uc_list[@]}" )
  newlist=()
  for it in "${pairs[@]}"; do
    name=${it%%:*}
    desc=${it#*:}
    newlist+=("${name}:${desc} — ${name}")
  done
  (( ${#newlist[@]} )) && zstyle ':completion:*:*:git:*' user-commands ${newlist[@]}
}

# Integrate with our lazy compinit flow: run after compinit on first Tab
__ami_after_compinit() {
  compdef __git_complete_with_aliases=git 2>/dev/null || compdef __git_complete_with_aliases git 2>/dev/null || true
  __git_load_and_override
  __git_apply_styles
  # Do not inject user-commands via zstyle to avoid one big group
}
