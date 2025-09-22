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
    emulate -L zsh -o extendedglob
    setopt local_options no_xtrace typesetsilent
    local -a user_cmds
    local raw key val name rec

    # Collect aliases from repo + 全局配置；repo 优先覆盖
    local repo_raw global_raw
    repo_raw=$(git config -z --get-regexp '^alias\.' 2>/dev/null || true)
    global_raw=$(git config --global -z --get-regexp '^alias\.' 2>/dev/null || true)

    local -a __records
    local -A __seen_alias
    __seen_alias=()

    if [[ -n $repo_raw ]]; then
      local -a __repo_records
      __repo_records=(${(0)repo_raw})
      local _rec _key _name
      for _rec in ${__repo_records[@]}; do
        _key=${_rec%%$'\n'*}
        _name=${_key#alias.}
        __records+=($_rec)
        __seen_alias[$_name]=1
      done
    fi
    if [[ -n $global_raw ]]; then
      local -a __global_records
      __global_records=(${(0)global_raw})
      local _rec _key _name
      for _rec in ${__global_records[@]}; do
        _key=${_rec%%$'\n'*}
        _name=${_key#alias.}
        [[ -n ${__seen_alias[$_name]} ]] && continue
        __records+=($_rec)
        __seen_alias[$_name]=1
      done
    fi

    (( ${#__records[@]} == 0 )) && return 0

    # Known alias descriptions（以当前 git config 为准）
    local -A desc_map
    desc_map=()
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

    # 初始化/克隆
    desc_map[init]='初始化仓库（默认分支 main）'
    desc_map[cl]='克隆仓库'
    desc_map[clg]='从 GitHub 克隆（HTTPS）'
    desc_map[clgp]='从 GitHub 克隆（SSH）'
    desc_map[clgu]='从 GitHub 克隆自己的仓库'

    # 状态/日志
    desc_map[s]='查看状态'
    desc_map[st]='查看状态'
    desc_map[stat]='查看状态'
    desc_map[sf]='简洁状态 + diff 统计'
    desc_map[l]='简洁图形化日志'
    desc_map[lg]='美化图形化日志（所有分支）'
    desc_map[default]='显示状态和最近 20 条日志'
    desc_map[filelog]='显示文件级详细改动'
    desc_map[changes]='显示提交的文件变化'
    desc_map[short]='简洁格式日志'
    desc_map[simple]='极简日志（仅提交信息）'
    desc_map[shortnocolor]='无颜色简洁日志'
    desc_map[recent-branches]='最近活跃分支'
    desc_map[ol]='查看引用日志'
    desc_map[contributors]='显示贡献者统计'

    # 暂存/提交
    desc_map[a]='添加文件到暂存区'
    desc_map[aa]='添加所有改动到暂存区'
    desc_map[chunkyadd]='交互式选择改动块'
    desc_map[ss]='暂存当前改动'
    desc_map[sl]='列出所有暂存'
    desc_map[sa]='应用暂存'
    desc_map[sd]='删除暂存'
    desc_map[snapshot]='创建带时间戳的快照'
    desc_map[snapshots]='列出所有快照暂存'
    desc_map[c]='快速提交（需提供提交信息）'
    desc_map[cm]='提交并指定提交信息'
    desc_map[ca]='添加所有改动并提交'
    desc_map[cc]='使用 git-commit-ai 生成提交信息并提交'
    desc_map[cam]='暂存所有改动并提交（传入提交信息）'
    desc_map[ci]='交互式提交'
    desc_map[amend]='修正上次提交'
    desc_map[ammend]='修正上次提交'
    desc_map[cp]='cherry-pick（保留原始引用）'
    desc_map[mt]='启动合并工具'

    # 差异/查看
    desc_map[d]='查看工作区改动'
    desc_map[dc]='查看暂存区改动'
    desc_map[last]='查看最后一次提交的改动'
    desc_map[dr]='查看指定提交的改动'
    desc_map[w]='显示提交详情'
    desc_map[ws]='显示提交统计'
    desc_map[ad]='使用 Araxis Merge 对比目录级改动'
    desc_map[ads]='使用 Araxis Merge 对比暂存区改动'
    desc_map[fn]='查看文件逐行作者'
    desc_map[fnr]='查看指定行范围作者'

    # 分支/工作树
    desc_map[b]='管理分支（列出/删除/切换）'
    desc_map[co]='切换分支或文件'
    desc_map[nb]='创建并切换到新分支'
    desc_map[wl]='列出所有工作树'
    desc_map[wa]='添加工作树'
    desc_map[wf]='删除工作树'
    desc_map[wa1]='添加编号为 1 的工作树（.jj/git-1）'
    desc_map[wa2]='添加编号为 2 的工作树（.jj/git-2）'
    desc_map[wa3]='添加编号为 3 的工作树（.jj/git-3）'
    desc_map[wo1]='进入工作树 1 并启动登录 shell'
    desc_map[wo2]='进入工作树 2 并启动登录 shell'
    desc_map[wo3]='进入工作树 3 并启动登录 shell'

    # 远程/推送/PR
    desc_map[r]='显示远程仓库'
    desc_map[pl]='拉取远程更新'
    desc_map[fo]='获取所有远程并清理'
    desc_map[f]='获取更新并 rebase 到 main'
    desc_map[ps]='推送到远程'
    desc_map[psa]='推送所有分支'
    desc_map[psd]='删除远程分支'
    desc_map[psb]='推送并设置上游'
    desc_map[pscb]='推送当前分支并设置上游'
    desc_map[pro]='为当前分支创建 PR'
    desc_map[pr]='推送当前分支并创建 PR'

    # Rebase / 多工作树流程
    desc_map[rb]='rebase（保留合并，自动暂存）'
    desc_map[rbt]='rebase 到 origin/main'
    desc_map[rbr]='交互式 rebase'
    desc_map[rc]='继续 rebase'
    desc_map[rs]='跳过当前提交'
    desc_map[wm1]='在工作树 1 执行 rebase'
    desc_map[wm2]='在工作树 2 执行 rebase'
    desc_map[wm3]='在工作树 3 执行 rebase'
    desc_map[ws1]='在工作树 1 内继续并完成 rebase'
    desc_map[ws2]='在工作树 2 内继续并完成 rebase'
    desc_map[ws3]='在工作树 3 内继续并完成 rebase'
    desc_map[wsa]='依次执行工作树 1/2/3 的 rebase 收尾'
    desc_map[wms1]='执行工作树 1 的 rebase 并串行处理其他工作树'
    desc_map[wms2]='执行工作树 2 的 rebase 并串行处理其他工作树'
    desc_map[wms3]='执行工作树 3 的 rebase 并串行处理其他工作树'
    desc_map[wmsa]='串行执行所有工作树 rebase 流程'

    # SVN / 其他
    desc_map[svnr]='SVN rebase'
    desc_map[svnd]='提交到 SVN'
    desc_map[svnl]='查看 SVN 日志'

    # 分类映射
    local -A cat_map; cat_map=()
    # 状态/日志（filelog 调整到 diff，减轻该组密度）
    for k in s st stat sf l lg default changes short simple shortnocolor ol contributors; do cat_map[$k]=status; done
    # 暂存/快照
    for k in a aa chunkyadd ss sl sa sd snapshot snapshots; do cat_map[$k]=stash; done
    # 分支/切换
    for k in b co nb recent-branches; do cat_map[$k]=branch; done
    # 提交
    for k in c cm ca cc cam ci amend ammend cp mt; do cat_map[$k]=commit; done
    # 差异/查看（包含 filelog）
    for k in d dc last dr w ws ad ads fn fnr filelog; do cat_map[$k]=diff; done
    # 远程/推送/拉取
    for k in r ps psa psd psb pscb pl fo f; do cat_map[$k]=remote; done
    # Rebase
    for k in rb rbt rbr rc rs wm1 wm2 wm3 ws1 ws2 ws3 wsa wms1 wms2 wms3 wmsa; do cat_map[$k]=rebase; done
    # PR
    for k in pro pr; do cat_map[$k]=pr; done
    # 工作树
    for k in wl wa wf wa1 wa2 wa3 wo1 wo2 wo3; do cat_map[$k]=worktree; done
    # 初始化/克隆
    for k in init cl clg clgp clgu; do cat_map[$k]=repo; done
    # Git Town
    for k in append hack kill new-pull-request prepend prune-branches rename-branch repo ship sync; do cat_map[$k]=town; done
    # SVN/其它杂项
    for k in svnr svnd svnl; do cat_map[$k]=other; done

    # 分类标签与顺序
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

    local -a _cat_order=(repo status stash branch commit diff remote rebase pr worktree town other)

    # Per-category buckets to preserve visual grouping order
    # One array per category (zsh does not support arrays as values of associative arrays)
    local -a \
      bucket_repo bucket_status bucket_stash bucket_branch bucket_commit \
      bucket_diff bucket_remote bucket_rebase bucket_pr bucket_worktree \
      bucket_town bucket_other

    # Split NUL-separated records safely in zsh
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
      local display_exp=${val//$'\n'/ }
      [[ -z $display_exp ]] && display_exp=${name}
      local desc="${label} — ${base_desc}：${display_exp}"
      # 避免 %-格式 / ! 历史展开影响描述显示
      desc=${desc//\%/%%}
      desc=${desc//!/\!}
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
  # Ensure _describe shows descriptions (applies to values type)
  zstyle ':completion:*:*:git:*:values' verbose yes
  zstyle ':completion:*:*:git:*' verbose yes
  # Do not sort matches; preserve emission order across groups
  zstyle ':completion:*:*:git:*' sort false
  # Plain text descriptions so fzf-tab recognizes groups
  zstyle ':completion:*:descriptions' format '[%d]'
  # Ensure per-item descriptions are shown with a clear separator
  zstyle ':completion:*:*:git:*:values' list-separator ' -- '
  # 不注入 fzf 预览，保留用户自定义
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
  setopt local_options no_xtrace
  builtin set +x 2>/dev/null || true
  __git_build_user_commands
  local -a __g8_essential __g8_statuslog __g8_viewdiff __g8_commitedit __g8_rebase __g8_branchworktree __g8_remotepr __g8_repoops
  local it name

  # 静音构建阶段（防止任何 echo/print 泄漏到列表顶部）
  local __ami_fd_out __ami_fd_err
  exec {__ami_fd_out}>&1 {__ami_fd_err}>&2
  exec >/dev/null 2>/dev/null

  # Helpers to append pairs
  __append_all() { local -a src=("$@"); (( ${#src[@]} )) && eval "$1"; }

  # status -> essential(core list) + statuslog(others)
  local -a _core_aliases
  if [[ -n ${AMI_GIT_CORE_ALIASES:-} ]]; then
    _core_aliases=(${=AMI_GIT_CORE_ALIASES})
  else
    _core_aliases=(s l)
  fi
  local -A _core_map; _core_map=()
  for name in ${_core_aliases[@]}; do _core_map[$name]=1; done
  for it in ${__git_bucket_status[@]}; do
    name=${it%%:*}
    if [[ -n ${_core_map[$name]:-} ]]; then
      __g8_essential+=("$it")
    else
      __g8_statuslog+=("$it")
    fi
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

  # 恢复输出后再发射候选（compadd 依赖 shell 环境而非 stdout）
  exec >&$__ami_fd_out 2>&$__ami_fd_err
  exec {__ami_fd_out}>&- {__ami_fd_err}>&-

  # Emit groups via compadd 确保每一项描述都传递给 fzf-tab
  __emit_group() {
    local _tag=$1 _label=$2; shift 2
    local -a _pairs=( "$@" ) _names _descs _p _n _d
    # 展开式显示策略：默认 full（所有组均展示展开式）
    # 可设置 AMI_GIT_ALIAS_EXPANSION=auto/none/full 覆盖
    local _policy=${AMI_GIT_ALIAS_EXPANSION:-full}
    local _cut=${AMI_GIT_ALIAS_EXP_WIDTH:-64}
    # 分隔符（可用 AMI_GIT_ALIAS_SEP1/SEP2 自定义）
    local sep1=${AMI_GIT_ALIAS_SEP1-' -- '}
    local sep2=${AMI_GIT_ALIAS_SEP2-' | '}
    # 在构建描述阶段彻底静音，防止 xtrace/echo 泄漏
    setopt local_options no_xtrace
    builtin set +x 2>/dev/null || true
    local __fd_o __fd_e
    exec {__fd_o}>&1 {__fd_e}>&2
    exec >/dev/null 2>/dev/null
    local -i _w=0
    # 计算本组别名列宽（左对齐，右侧填充空格），并限制上限
    for _p in ${_pairs[@]}; do
      _n=${_p%%:*}
      (( ${#_n} > _w )) && _w=${#_n}
    done
    ((_w+=1))
    ((_w>24)) && _w=24

    for _p in ${_pairs[@]}; do
      _n=${_p%%:*}; _d=${_p#*:}
      # 去掉前缀“组标签 — ”（组名已在标题里显示）
      local _body=$_d
      [[ $_body == *' — '* ]] && _body=${_body#* — }
      # 拆分“用途：展开式”（默认也展示展开式；策略可调）
      local _base=$_body __ami_exp
      if [[ $_body == *'：'* ]]; then
        _base=${_body%%：*}
        __ami_exp=${_body#*：}
      fi
      local _alias_col=${(r:${_w}:: :)_n}
      # 按策略构造：别名列 + 用途 [+ 展开式]，分隔符可自定义
      local __ami_line
      local showexp=1
      case $_policy in
        (none) showexp=0 ;;
        (auto) [[ $_tag == git8-statuslog ]] && showexp=0 ;;
        (full) showexp=1 ;;
      esac
      if (( showexp )) && [[ -n $__ami_exp ]]; then
        local _e=$__ami_exp
        if (( ${#_e} > _cut )); then
          _e=${_e[1,_cut]}…
        fi
        __ami_line="${_alias_col}${sep1}${_base}${sep2}${_e}"
      else
        __ami_line="${_alias_col}${sep1}${_base}"
      fi
      _names+=("$_n"); _descs+=("$__ami_line")
    done
    # 还原输出后再发射
    exec >&$__fd_o 2>&$__fd_e
    exec {__fd_o}>&- {__fd_e}>&-
    (( ${#_names[@]} )) || return 0
    compadd -Q -o nosort -J "${_tag}" -X "${_label}" -d _descs -- ${_names[@]}
  }
  (( ${#__g8_essential[@]}      )) && __emit_group git8-essential      'Core'          ${__g8_essential[@]}
  (( ${#__g8_statuslog[@]}      )) && __emit_group git8-statuslog      'Status/Log'    ${__g8_statuslog[@]}
  (( ${#__g8_viewdiff[@]}       )) && __emit_group git8-viewdiff       'View/Diff'     ${__g8_viewdiff[@]}
  (( ${#__g8_commitedit[@]}     )) && __emit_group git8-commitedit     'Commit/Stage'  ${__g8_commitedit[@]}
  (( ${#__g8_rebase[@]}         )) && __emit_group git8-rebase         'Rebase'        ${__g8_rebase[@]}
  (( ${#__g8_branchworktree[@]} )) && __emit_group git8-branchworktree 'Branch/WT'     ${__g8_branchworktree[@]}
  (( ${#__g8_remotepr[@]}       )) && __emit_group git8-remotepr       'Remote/PR'     ${__g8_remotepr[@]}
  (( ${#__g8_repoops[@]}        )) && __emit_group git8-repoops        'Repo/Ops'      ${__g8_repoops[@]}
}

  __git_complete_with_aliases() {
  emulate -L zsh
  setopt local_options no_xtrace
  autoload -Uz _git 2>/dev/null || true
  # Ensure our overrides are loaded before any emission
  __git_load_and_override
  __git_apply_styles
  # Ensure fzf-tab shows descriptions and groups
  zstyle ':fzf-tab:complete:git:*' descriptions yes 2>/dev/null || true
  zstyle ':fzf-tab:complete:git:*' show-group yes 2>/dev/null || true
  # 完整静音运行 _git，避免任何 stdout/stderr 内容顶到弹窗顶部
  local __ami_out __ami_err __ret=0
  exec {__ami_out}>&1 {__ami_err}>&2
  { _git } >/dev/null 2>/dev/null || __ret=$?
  exec >&$__ami_out 2>&$__ami_err
  exec {__ami_out}>&- {__ami_err}>&-
  return $__ret
}

# Install wrapper mapping now and ensure it persists after compinit
compdef __git_complete_with_aliases=git 2>/dev/null || compdef __git_complete_with_aliases git 2>/dev/null || true
# 为 g 函数添加 git 补全（加在此处也可以）
# compdef g=git 2>/dev/null || true
if [[ $- == *i* ]]; then
  autoload -Uz add-zsh-hook 2>/dev/null || true
  # 轻量兜底：每次 precmd 重新保证 git 的 compdef 指向我们
  __git_compdef_always() {
    compdef __git_complete_with_aliases=git
    # compdef g=git 2>/dev/null || true
  }
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
  # 为 g 函数添加 git 补全（此处的是有用的）
  compdef g=git 2>/dev/null || true
  __git_load_and_override
  __git_apply_styles
  # Do not inject user-commands via zstyle to avoid one big group
}
