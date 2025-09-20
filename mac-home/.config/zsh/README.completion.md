# Git/JJ 智能补全（分组版）+ report-kit CLI

本配置为 zsh + fzf-tab 定制的 Git/JJ 命令智能补全，并追加 report-kit CLI 懒加载注册，核心特性：

- Git 别名按 8 个任务域分组显示（可选隐藏系统命令组）
- JJ 别名按 8 个任务域分组显示（commands/command 置于最后）
- 分组顺序与候选顺序稳定一致（禁用排序、一次性发射）
- 组内按别名名称字母序稳定展示
- 提供调试工具，便于排查分组与排序问题
- report-kit CLI 补全按需注册（`report-kit completion zsh` 延后执行）

---

## 目录结构

- `~/.config/zsh/git-completion-enhanced.zsh`
  - Git 补全增强（只输出 8 个别名分组，可选隐藏系统命令组）
- `~/.config/zsh/jj-completion-enhanced.zsh`
  - JJ 补全增强（输出 8 个别名分组，内建 commands 在最后）
- `~/.config/zsh/report-kit-completion.zsh`
  - report-kit CLI 补全（懒加载，首次 Tab 后注册）
- `~/.config/zsh/stowx-completion.zsh`
  - stowx CLI 补全（懒加载，解析 STOW_DIR 包列表）
- `~/.config/zsh/zstyles.zsh`
  - fzf-tab 主题与行为（`--no-sort`）、completion 基础样式（`menu no`、`[ %d ]` 组名）；与 `~/.config/zsh/fzf.zsh` 共用 `--color=light,fg:#3a4d53,bg:#fbf3db,hl:#0072d4,fg+:#3a4d53,bg+:#e9e4d4,hl+:#0072d4,info:#009c8f,prompt:#c25d1e,spinner:#ca4898,pointer:#0072d4,marker:#ad8900,header:#489100,gutter:#fbf3db` 配色与按键绑定；若存在 `~/.local/bin/check_term_theme.py` 会在首次 Tab/`ctrl+R`/`fzf` 时自动侦测终端主题，也可随时执行 `ami-fzf-apply-theme dark|light` 手动切换并同步 fzf-tab
- `~/.config/zsh/zshrc`
  - 串联各模块：加载 lazyload、fzf、zstyles，并留给本地定制入口
- `~/.config/zsh/lazyload.zsh`
  - 负责懒加载：首次 Tab 时按需 `source` 上述脚本，并在 `compinit` 之后挂接生效
- `~/.config/zsh/functions/ftb-debug-{on,off}`、`ftb-debug-dump`
  - fzf-tab 调试工具：捕获本次补全的分组与候选顺序到临时文件

---

## 预置要求

- zsh ≥ 5.8，已安装 [fzf-tab](https://github.com/Aloxaf/fzf-tab)
- compinit 在首次 Tab 触发；fzf-tab 由 Zim 预加载，但其补全在 compinit 之后生效（无需在 zshrc 手动排序）
- 当前配置已由 `~/.config/zsh/lazyload.zsh` 懒加载，无需在 `~/.zshrc` 直接 `source`

重载配置：

```zsh
exec zsh -l
```

## report-kit：一次性注册

- 首次 Tab 前由懒加载架构捕获 `compdef`，待 `compinit` 完成后执行 `report-kit completion zsh --fallback` 并注册 `_shtab_report_kit`。
- 可通过 `print -r -- $REPORT_KIT_COMPLETION_READY` 验证脚本是否被捕获；`type -a report-kit` 确认可执行。
- 若未安装 report-kit，脚本会跳过注册且不影响其他补全；安装后重新 `exec zsh -l` 即可。
- 懒加载脚本默认调用 `report-kit completion zsh --fallback`，因此首个 Tab 就会显示带描述的子命令；设 `REPORT_KIT_COMPLETION_FALLBACK=0` 可恢复上游行为，设为 auto 则按需侦测 fzf-tab/zsh-autocomplete。
- 与 fzf-tab 配合时会把候选改写为 `命令 - 描述`，确保弹窗中依旧可以看到详情而不只剩命令名。
- 仍可通过 `zstyle` 控制描述显示样式；若完全不需要描述，也可禁用相关样式。
- 如定义了指向 `report-kit` 的 alias（例如 `rk`），会在懒加载阶段按别名调用 `report-kit completion zsh --fallback --prog <alias>` 生成专属补全脚本，并修正 fallback 条件为 alias 名称，别名与本体均首个 Tab 即带描述。

## stowx：按需注册

- 懒加载流程捕获 `compdef`，`compinit` 之后执行内置 `_stowx` 注册；`print -r -- $STOWX_COMPLETION_READY` 可验证脚本已装入。
- 支持子命令与包名提示：`preview/apply/adopt/unstow/restow` 等会读取 `STOW_DIR`（可被 `-d/--dir` 覆盖）列出台下的包。
- `grab` 子命令保持 `_files` 行为补齐抓取路径；若输入 `--` 之后则回落到默认补全以便继续传递给 GNU Stow。
- `stowx` 未安装时脚本自动跳过，不影响其它补全；安装后重新开启登录 shell 即可生效。

## Git：8 组别名（系统命令可隐藏/可恢复）

> 当前已默认“隐藏系统命令组”，只展示别名 8 组；如需恢复见文末“可选项”。

> 下方“Git 别名详解（按组）”为唯一事实来源（SSOT）。这里不再重复列清单。

分组实现要点：

- blame（fn/fnr）→ 归入“查看/差异”；
- Araxis 目录对比（ad/ads）→ 归入“查看/差异”；
- add/patch add/mergetool/cherry-pick → 归入“提交/暂存”；
- reflog/贡献者 → 归入“状态/日志”；
- SVN 三件套、Git Town → 归入“仓库/协作”。

为什么是这 8 组？

- 贴合 Git 官方 Porcelain 职责，面向“日常工作域”而不是底层命令族；
- 降低查找成本：读状态/读历史、看变化、组织提交、线性化、本地开发单元、对外同步、仓库生命周期、高频入口。
- 尽量避免“其他”：通过别名模式路由，将易歧义命令（如 blame/difftool/svn/pr 流程）定向到常见场景。

想改组？（快速路由）

- 编辑 `git-completion-enhanced.zsh` 的 `__git_emit_ami_alias_groups`：
  - 在“other → 路由”里追加你的别名映射：
    ```zsh
    case $name in
      myalias) __g8_viewdiff+=("$it") ;;
      # ... 或路由到 __g8_commitedit/__g8_remotepr 等
    esac
    ```
  - 或者前面组装阶段，按需要把某个桶（如 `__git_bucket_worktree`）整体并到其它组。

自定义显示顺序

- 改 `_describe -t git8-... '组名' 组数组` 的顺序即可（同一函数内，顺序即显示顺序）。
- 若需要系统命令“commands”作为末尾补充组，见下方“恢复系统命令组（可选）”。

---

### Git 别名详解（按组）

以下为你常用 Git 别名的用途释义与代表性展开（若与你本机 `git config -l` 不同，以本机为准）。

- 核心（入口/高频）
  - s: 状态总览（`git status`）
  - l: 简洁图形化日志（`git log --graph --date=short …`）

- 状态/日志（读状态/读历史/汇总）
  - st/stat: 状态（`git status`）
  - sf: 简洁状态 + diff 统计（`status --short --branch; diff --stat`）
  - lg: 全量图形化日志（`--decorate --abbrev-commit --date=relative --pretty=jj --all`）
  - changes: 提交变更列表（`log --pretty=… --name-status`）
  - short/simple/shortnocolor: 精简日志视图（不同 `--pretty` 模板）
  - filelog: 单文件级历史（`git log -u -- <file>`）
  - default: 快速总览（先 `sf` 再 `lg -n 20`）
  - ol: 操作日志（`git reflog`）
  - contributors: 贡献者统计（`git shortlog --summary --numbered --email`）

- 查看/差异（看对象/看变更）
  - d/dc: 差异（工作区/暂存区，`git diff` / `git diff --cached`）
  - dr/last: 指定/上一次提交的差异（`git diff ${1:-HEAD}` / `git diff HEAD^`）
  - w/ws: 提交详情/统计（`git show` / `git show --stat`）
  - ad/ads: 目录级对比（Araxis difftool；含暂存区版）
  - fn/fnr: 逐行追责/指定范围追责（`git blame` / `git blame -L <range> -- <file>`）

- 提交/暂存（组织改动与形成提交）
  - a/chunkyadd: 暂存/交互暂存（`git add` / `git add --patch`）
  - c/ca/ci: 提交（快速消息/全部改动/交互式）
  - amend/ammend: 修订上次提交（`git commit --amend`；`ammend` 为兼容拼写）
  - ss/sl/sa/sd: stash（保存/列表/应用/删除）
  - snapshot/snapshots: 快照工作区（保存并列出贴“snapshot”标签的 stash）
  - cp: 挑拣（`git cherry-pick -x` 保留来源）
  - mt: 合并工具（`git mergetool`）

- Rebase（线性化与拼接）
  - rb: 基础 rebase（`--rebase-merges --autostash`）
  - rbt: rebase 到 `origin/main`
  - rbr: 交互式 rebase（`-i`）
  - rc/rs: 流程控制（继续/跳过）

- 分支/工作树（本地开发单元）
  - b: 分支列表（含最近提交，`git branch -v`）
  - co: 切换分支/文件（`git checkout`）
  - nb: 新建并切换（`git checkout -b`）
  - recent-branches: 最近活跃分支（`git for-each-ref --sort=-committerdate`）
  - wl/wa/wf: 工作树列表/新增/删除（`git worktree`）

- 远程/推送/PR（对外协作）
  - r: 远程仓库（`git remote -v`）
  - pl: 拉取（`git pull`）
  - fo/f: 获取/集成（`git fetch --all --prune`；`f` 还会 `rbt`）
  - ps/psa/psd/psb/pscb: 多种推送（默认/所有/删除/设上游/当前分支）
  - pro/pr: 创建 PR（当前分支；或先推送再创建）

- 仓库/协作（生命周期与生态）
  - init: 初始化并设置默认分支 `main`
  - cl/clg/clgp/clgu: 多种克隆（本地/HTTPS/SSH/个人仓库）
  - svnr/svnd/svnl: SVN 双向（rebase/dcommit/log）
  - Git Town: append/hack/kill/new-pull-request/prepend/prune-branches/rename-branch/repo/ship/sync（特性分支协作流）

## JJ：8 组别名规划（commands 在最后）

1) 核心（`essential-aliases`）
   - s, l

2) 状态/日志/操作（`statuslog-aliases`）
   - sf, lg, lp, lr, ls, default, ol, or, ow, owp

3) 查看/差异（`viewdiff-aliases`）
   - w, ws, d, dr

4) 提交/编辑（`commit-edit-aliases`）
   - ci, cm, cim, de, dem,
   - n*/na*/nb*（创建/插入/前插等），
   - ad/adb/adk（放弃），sp*/sq*（拆分/合并），
   - ep/epc/en/enc/eh（导航），ab/abf（吸收）

5) Rebase（`rebase-aliases`）
   - 全部 rb* 系列

6) 书签/分支（`bookmark-aliases`）
   - b[dflrstu]*, bmw, bmb, br, bs, bsr, bst, bt, bu

7) 远程/推送/PR（`remote-repo-aliases`）
   - f, fw, fo, fa, faw, ps*, pr*, pro/prow/prw

8) 工作区/文件（`workspace-file-aliases`）
   - wl, wa*, wf*, wo*, wr, fn*, ft, fu, re, ui

commands/command：始终放在分组之后显示。

JJ 组设计原则（与 Git 的异同）

- JJ 别名覆盖“查看/差异、提交/编辑、Rebase、书签/分支、远程/PR、工作区/文件”等任务域，与 Git 相同；
- 相比 Git，多了“吸收改动/操作日志”等更细颗粒别名，已并入相近任务域（减少组数量，避免“其他”）；
- commands/command 结尾保留 JJ 原生命令，避免信息缺失。

---

### JJ 别名详解（按组）

> 以下结合你现有 JJ 别名分类规则整理（如与 `jj config list --user` 不同，以本机为准）。

- 核心（入口/高频）
  - s: 查看状态
  - l: 查看日志

- 状态/日志/操作
  - sf: 当前改动摘要（status + diff 摘要）
  - lg/lp/lr/ls: 多种日志视图（全部/私有/范围/栈）
  - default: 总览（状态 + 最近日志）
  - ol/or/ow/owp: 操作日志/回滚/详情/改动

- 查看/差异
  - w/ws: 查看提交详情/统计
  - d/dr: 查看当前/指定版本的改动

- 提交/编辑（含导航/拆分/合并/放弃/吸收）
  - ci/cm/cim: 提交（交互式/快速/交互快速）
  - de/dem: 编辑/设置描述
  - n*/na*/nb*: 创建/插入/前插（及消息版）
  - ep/epc/en/enc/eh: 导航到前/后/冲突提交等
  - ad/adb/adk: 放弃（可保留书签/恢复后代）
  - sp*/spr/spp: 拆分（交互式/并行/指定提交）
  - sq*/sqr/sqa/sqat: 合并/压缩到指定/父提交（交互/自动）
  - ab/abf: 吸收改动（从当前/指定提交）

- Rebase（线性化与拼接）
  - 全部 `rb*` 系列：到目标、到 trunk、以源/目标/位置变体，含 `--insert-{before,after}` 等

- 书签/分支（Bookmarks）
  - b[dflrstu]*: 删除/忘记/列表/重命名/设置等
  - bmw/bmb: 移动当前链/分支的书签
  - br/bs/bsr/bst: 重命名/设置/设置到指定/设置到 trunk
  - bt/bu: 跟踪/取消跟踪远程书签

- 远程/推送/PR
  - f, fw, fo, fa, faw: fetch/同步（可监视 PR 检查后自动同步）
  - ps*, psb, psc/w, psca, psa, psd, psm/s: 多种推送（书签/提交/当前链/所有可见/所有/删除/到 main/master）
  - pro/pr/prow/prw: 创建 PR（当前分支/链，或先推送再创建）

- 工作区/文件
  - wl/wa*/wo*/wf*/wr: 工作区列表/添加/切换/忘记/重命名（含预设 1/2/3）
  - fn/fnr: 文件注释/指定版本注释（blame 等价）
  - ft/fu/re: 跟踪/取消跟踪/恢复文件
  - ui: 启动 UI（jjui）

## 验证与调试

重载后可用以下方式核对实际分组与顺序：

```zsh
exec zsh -l
ftb-debug-on
git  # 或 jj，然后按 <Tab>
# 终端会提示日志路径，查看：
cat /tmp/fzf-tab-debug-*.log
ftb-debug-off
```

日志包含：
- headers：分组标题（多列排版，从左到右再换行）
- groups：分组列表（线性顺序）
- candidates：候选顺序（每项带所属分组，真实传给 fzf 的顺序）

如发现顺序不一致：
- 确认 `:completion:*:*:git:* sort false` 与 fzf `--no-sort` 均生效；
- 确认没有其它插件在 git/jj 上设置 tag-order/group-order（`zstyle -L` 检查）。

常用排错命令：

```zsh
zstyle -L ':completion:*:*:git:*'            # 查看 git 的样式（sort、tag/group-order）
zstyle -L ':fzf-tab:complete:git:*'          # 查看 git 在 fzf-tab 下的样式
whence -v _git                               # 确认系统 _git 源头
whence -v __git_complete_with_aliases        # 确认增强包装函数已加载
bindkey '^I'                                 # 确认 Tab 由 fzf-tab-complete 负责
```

自检（打印“组 → 别名”）：

```zsh
git-groups-dump   # 打印当前 Git 8 组及各组别名（含描述）
jj-groups-dump    # 打印当前 JJ 8 组及各组别名（name=value）
comp-groups-dump  # 两者都打印
```

---

## 自定义

调整显示顺序：

- Git：编辑 `git-completion-enhanced.zsh` 中 `__git_emit_ami_alias_groups` 的 `_describe` 顺序；
- JJ：编辑 `jj-completion-enhanced.zsh` 中 `_jj_commands` 的 `_describe` 顺序，或仅调整 zstyle `group-order`。

重分类/微调：

- Git：在 `__git_emit_ami_alias_groups` 的“other → 路由”分支中，按别名名称追加单条路由（如将某别名改派到 viewdiff/commitedit 等）。
- JJ：在 `_jj_commands` 的分类 `case` 中调整对应别名集合。

恢复 Git 系统命令组（可选）：

1) 将 `_git_commands()` 包装逻辑改为：先 `__git_emit_ami_alias_groups`，再调用原始 `_git_commands_original`；
2) 在 `__git_apply_styles` 的 tag/group-order 末尾追加 `commands`；
3) 如仍需隐藏系统“aliases”组，保持不包含 `aliases` 标签。

仅仅把系统组放到最后？

- 将 `_git_commands()` 从 `return 0` 改为：
  ```zsh
  __git_emit_ami_alias_groups "$@"
  _git_commands_original "$@"
  ```
- 并在 `__git_apply_styles` 的 `tag-order/group-order` 末尾追加 `commands`；
- 这样就是“8 个别名组 + 系统命令组（最后）”。

---

## 常见问题

- 组头的多列排版是“左→右→换行”，不是“逐行阅读”；候选顺序以 `candidates` 为准（已与组顺序一致）。
- 若出现重复/错位：多半是其它插件注入了 tag-order 或覆盖 compdef；重载并执行 `zstyle -d ':completion:*:*:git:*' {tag-order,user-commands}` 后再试。
- fzf-tab 会临时关闭 list-grouped；无需在 zshrc 强制 `list-grouped yes`。本配置已经精简为 `menu no` + `descriptions [ %d ]`。

与 Zim/fzf/其它插件的相容性

- compinit 在首次 Tab 触发；fzf-tab 实际工作发生在 compinit 之后（无需手动调整加载顺序）；
- 不要再加载 fzf 的自带 Tab 补全（会与 fzf-tab 抢 Tab）；
- 不建议在 zshrc 里对 git/jj 再设置 tag-order/group-order（避免与本增强脚本冲突）。

验证懒加载是否生效

```zsh
exec zsh -l
print -r -- $GIT_COMPLETION_ENHANCED   # 启动后应为空（尚未加载脚本）
# 按一次 Tab 或等首个提示符触发后：
print -r -- $GIT_COMPLETION_ENHANCED   # 变为 1，表示脚本已加载
```

性能与可靠性

- 仅发射一次候选、禁排序，fzf 展示不再“跳动”；
- 懒加载 compinit，首个 Tab 自动补齐初始化与增强挂接；
- 变更后若遇到缓存问题，执行一次 `exec zsh -l` 即可。

---

## 变更与维护

- Git/JJ 的增强脚本尽量“单处发射候选、禁排序、清晰分组”，可读性强；
- 如升级 zsh/fzf-tab 后出现行为变化，可先用 `ftb-debug-on` 抓取一次日志再调整；
- 欢迎按个人使用习惯，微调 8 组的顺序、路由与标题文案。
