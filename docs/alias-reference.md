# Git & JJ Alias 参考文档

这个文档包含了所有 git 和 jj 的 alias 及其描述，便于快速查找和理解每个命令的用途。

## Git Aliases

### 可视化对比工具 (Araxis Merge)
- `ad` → `difftool --tool=araxis --dir-diff` - 使用 Araxis Merge 对比目录级改动
- `ads` → `difftool --tool=araxis --dir-diff --staged` - 使用 Araxis Merge 对比暂存区改动

### Git Town 工作流命令
- `append` → `town append` - 在当前分支后追加新分支
- `hack` → `town hack` - 创建新的 feature 分支
- `kill` → `town kill` - 删除当前分支并切回父分支  
- `new-pull-request` → `town new-pull-request` - 创建 PR
- `prepend` → `town prepend` - 在当前分支前插入新分支
- `prune-branches` → `town prune-branches` - 清理已合并的分支
- `rename-branch` → `town rename-branch` - 重命名当前分支
- `repo` → `town repo` - 在浏览器中打开仓库页面
- `ship` → `town ship` - 合并当前分支到主分支
- `sync` → `town sync` - 同步当前分支与远程

### 仓库初始化与克隆
- `init` → 初始化仓库并设置默认分支为 main
- `cl` → `clone` - 克隆仓库
- `clg <user/repo>` → 从 GitHub 克隆（HTTPS）
- `clgp <user/repo>` → 从 GitHub 克隆（SSH）
- `clgu <repo>` → 从 GitHub 克隆自己的仓库（SSH）

### 状态查看
- `s`/`st`/`stat` → `status` - 查看状态
- `sf` → 简洁状态 + diff 统计信息
- `default` → 显示状态和最近 20 条日志

### 日志查看
- `l` → `log --graph --date=short` - 简洁图形化日志
- `lg` → 美化的图形化日志，显示所有分支
- `changes` → 显示提交的文件变化
- `short` → 简洁格式日志
- `simple` → 极简格式日志（仅提交信息）
- `shortnocolor` → 无颜色简洁日志
- `filelog` → 显示文件级别的详细改动
- `recent-branches` → 显示最近 15 个活跃分支

### 添加文件
- `a` → `add` - 添加文件到暂存区
- `chunkyadd` → `add --patch` - 交互式选择要添加的改动块

### 暂存（Stash）
- `ss` → `stash` - 暂存当前改动
- `sl` → `stash list` - 列出所有暂存
- `sa` → `stash apply` - 应用暂存
- `sd` → `stash drop` - 删除暂存
- `snapshot` → 创建带时间戳的快照暂存
- `snapshots` → 列出所有快照暂存

### 分支管理
- `b` → `branch -v` - 显示分支列表（含最新提交）
- `co` → `checkout` - 切换分支/文件
- `nb` → `checkout -b` - 创建并切换到新分支

### 提交
- `c <message>` → `commit -m` - 快速提交
- `ca <message>` → `commit -am` - 添加所有改动并提交
- `ci` → `commit` - 交互式提交
- `amend`/`ammend` → `commit --amend` - 修正上次提交

### 差异对比
- `d` → `diff` - 查看工作区改动
- `dc` → `diff --cached` - 查看暂存区改动
- `last` → `diff HEAD^` - 查看最后一次提交的改动
- `dr [commit]` → 查看指定提交的改动（默认 HEAD）
- `w` → `show` - 显示提交详情
- `ws` → `show --stat` - 显示提交统计

### 远程操作
- `r` → `remote -v` - 显示远程仓库
- `ps` → `push` - 推送到远程
- `psa` → `push --all` - 推送所有分支
- `psd <branch>` → 删除远程分支
- `psb [branch]` → 推送并设置上游（默认当前分支）
- `pscb [branch]` → 推送当前分支（默认当前分支）
- `pl` → `pull` - 拉取远程更新
- `fo` → `fetch --all --prune` - 获取所有远程更新并清理
- `f` → 获取更新并 rebase 到 main

### Rebase
- `rb` → `rebase --rebase-merges --autostash` - 智能 rebase
- `rbt` → rebase 到 origin/main
- `rbr` → 交互式 rebase
- `rc` → `rebase --continue` - 继续 rebase
- `rs` → `rebase --skip` - 跳过当前提交

### Pull Request (需要 gh CLI)
- `pro` → 为当前分支创建 PR
- `pr [branch]` → 推送分支并创建 PR

### Worktree
- `wl` → `worktree list` - 列出所有工作树
- `wa <branch> [path]` → 添加工作树
- `wf <path>` → 删除工作树

### 其他工具
- `cp` → `cherry-pick -x` - 复制提交（保留原始引用）
- `ol` → `reflog` - 查看引用日志
- `fn` → `blame` - 查看文件的逐行作者
- `fnr <file> <line-range>` → 查看指定行范围的作者
- `contributors` → 显示贡献者统计
- `mt` → `mergetool` - 启动合并工具

### SVN 集成
- `svnr` → `svn rebase` - SVN rebase
- `svnd` → `svn dcommit` - 提交到 SVN
- `svnl` → `svn log --oneline --show-commit` - 查看 SVN 日志

---

## JJ (Jujutsu) Aliases

### 状态与日志
- `s` → `status` - 查看状态
- `sf` → 当前改动的 diff 摘要
- `l` → `log` - 查看日志
- `lr <revset>` → 查看指定版本集的日志
- `ls` → 查看 stash 日志
- `lp` → 查看私有（非 stash）提交
- `lg` → 查看所有提交
- `default` → 显示状态和最近 20 条日志

### 仓库初始化与克隆
- `init` → `git init --colocate` - 初始化 Git 共存仓库
- `cl` → `git clone --colocate` - 克隆为 Git 共存仓库
- `clg <user/repo>` → 从 GitHub 克隆（HTTPS）
- `clgp <user/repo>` → 从 GitHub 克隆（SSH）
- `clgu <repo>` → 从 GitHub 克隆自己的仓库
- `clsp <user/repo>` → 从 Sourcehut 克隆（SSH）
- `clsu <repo>` → 从 Sourcehut 克隆自己的仓库

### 差异对比
- `d` → `diff` - 查看当前改动
- `dr <revset>` → 查看指定版本的改动

### 创建新提交
- `n` → `new` - 创建新提交
- `nm <message>` → 创建新提交并设置消息
- `nt` → 从 trunk 创建新提交
- `ntm <message>` → 从 trunk 创建新提交并设置消息
- `na <revset>` → 在指定提交后插入新提交
- `nae` → 在当前提交后插入新提交
- `naem <message>` → 在当前提交后插入新提交并设置消息
- `nb <revset>` → 在指定提交前插入新提交
- `nbe` → 在当前提交前插入新提交
- `nbem <message>` → 在当前提交前插入新提交并设置消息

### 描述与提交
- `de` → `describe` - 编辑提交描述
- `dem <message>` → 设置提交描述
- `ci` → `commit -i` - 交互式提交
- `cm <message>` → 快速提交
- `cim <message>` → 交互式快速提交

### 查看提交
- `w` → `show` - 显示提交详情
- `ws` → `show --stat` - 显示提交统计

### 编辑与导航
- `e` → `edit` - 编辑提交
- `eh` → 编辑当前提交链的所有头部
- `ep` → 编辑前一个提交
- `epc` → 编辑前一个冲突提交
- `en` → 编辑下一个提交
- `enc` → 编辑下一个冲突提交

### 放弃提交
- `ad` → `abandon` - 放弃提交
- `adb` → 放弃但保留书签
- `adk` → 放弃但保留书签并恢复后代

### 拆分与合并
- `sp` → `split` - 交互式拆分提交
- `spr <revset>` → 拆分指定提交
- `spp` → 并行拆分（创建兄弟提交）
- `sppr <revset>` → 并行拆分指定提交
- `sq` → `squash -i` - 交互式合并到父提交
- `sqa` → 自动合并到父提交
- `sqt <revset>` → 交互式合并到指定提交
- `sqat <revset>` → 自动合并到指定提交
- `sqf <revset>` → 交互式从指定提交合并
- `sqaf <revset>` → 自动从指定提交合并
- `sqr <revset>` → 交互式合并指定提交
- `sqar <revset>` → 自动合并指定提交

### Rebase（跳过空提交）
- `rb` → 基础 rebase
- `rba <revset>` → rebase 到指定提交之后
- `rbb <revset>` → rebase 到指定提交之前
- `rbd <revset>` → rebase 到指定目标
- `rbt` → rebase 到 trunk
- `rbtr <revset>` → 将指定提交 rebase 到 trunk
- `rbtw` → 将当前提交链 rebase 到 trunk
- `rbte` → 将当前提交 rebase 到 trunk
- `rbtb <branch>` → 将分支 rebase 到 trunk
- `rbta` → 将所有可变头部 rebase 到 trunk
- `rbts <revset>` → 从指定源 rebase 到 trunk
- `rbtse` → 从当前提交 rebase 到 trunk
- `rbe` → rebase 到当前提交
- `rber <revset>` → 将指定提交 rebase 到当前
- `rbeb <branch>` → 将分支 rebase 到当前
- `rbes <revset>` → 从指定源 rebase 到当前
- `rbs <revset>` → 从指定源开始 rebase
- `rbse` → 从当前提交开始 rebase
- `rbsed <revset>` → 从当前 rebase 到指定目标
- `rbsea <revset>` → 从当前 rebase 到指定提交之后
- `rbseb <revset>` → 从当前 rebase 到指定提交之前
- `rbr <revset>` → rebase 指定提交
- `rbrw` → rebase 当前提交链
- `rbrwd <revset>` → 将当前提交链 rebase 到指定目标
- `rbrwa <revset>` → 将当前提交链 rebase 到指定提交之后
- `rbrwb <revset>` → 将当前提交链 rebase 到指定提交之前
- `rbre` → rebase 当前提交
- `rbred <revset>` → 将当前提交 rebase 到指定目标
- `rbrea <revset>` → 将当前提交 rebase 到指定提交之后
- `rbreb <revset>` → 将当前提交 rebase 到指定提交之前
- `rbrb <branch>` → rebase 分支

### Absorb（自动分配改动到历史提交）
- `ab` → `absorb` - 自动吸收改动到相关提交
- `abf <revset>` → 从指定提交开始吸收

### 恢复
- `re` → `restore` - 恢复文件

### 书签管理
- `bd` → 删除书签
- `bf` → 忘记书签
- `bl` → 列出所有书签（含远程）
- `blr <revset>` → 列出指定版本的书签
- `blrw` → 列出当前提交链的书签
- `blrb` → 列出当前分支的书签
- `bmw` → 移动当前提交链的书签
- `bmb` → 移动当前分支的书签
- `br` → 重命名书签
- `bs` → 设置书签
- `bsr <revset>` → 设置书签到指定提交（允许后退）
- `bst` → 设置书签到 trunk
- `bt` → 跟踪远程书签
- `bu` → 取消跟踪远程书签

### Git 集成与同步
- `f` → 获取更新并 rebase 到 trunk
- `fw <pr>` → 监视 PR 检查状态后同步
- `fo` → `git fetch --all-remotes` - 获取所有远程更新
- `fa` → 获取更新并 rebase 所有分支到 trunk
- `faw <pr>` → 监视 PR 检查后同步所有分支
- `ps` → `git push` - 推送到远程
- `psb <bookmark>` → 推送书签
- `psc <revset>` → 推送指定提交
- `pscw` → 推送当前提交链
- `pscb` → 推送当前分支
- `psca` → 推送所有可见非私有头部
- `psa` → 推送所有
- `psd` → 推送删除
- `psm` → 推送到 main（设置书签到父提交）
- `psms` → 推送到 master（设置书签到父提交）

### Pull Request（需要 gh CLI）
- `pro` → 为当前分支创建 PR
- `pr` → 推送当前分支并创建 PR
- `prow` → 为当前提交链创建 PR
- `prw` → 推送当前提交链并创建 PR

### 操作日志
- `ol` → `op log` - 查看操作日志
- `or` → `op restore` - 恢复到指定操作
- `ow` → `op show` - 显示操作详情
- `owp` → `op show --patch` - 显示操作的改动

### 文件操作
- `fn` → `file annotate` - 查看文件注释（类似 blame）
- `fnr <revset>` → 查看指定版本的文件注释
- `ft` → `file track` - 跟踪文件
- `fu` → `file untrack` - 取消跟踪文件

### 工作区管理
- `wl` → `workspace list` - 列出工作区
- `wa` → `workspace add` - 添加工作区
- `wa1`/`wa2`/`wa3` → 添加预定义工作区 1/2/3
- `wo1`/`wo2`/`wo3` → 切换到工作区 1/2/3
- `wf` → `workspace forget` - 忘记工作区
- `wf1`/`wf2`/`wf3` → 忘记工作区 1/2/3
- `wr` → `workspace rename` - 重命名工作区

### UI 工具
- `ui` → 启动 jjui 查看所有提交

---

## 使用技巧

### Git
1. **快速提交流程**：`ga` → `c "message"` 或直接 `ca "message"`
2. **查看最近改动**：`sf` 或 `default`
3. **分支工作流**：`nb feature` → 开发 → `pr` → 合并
4. **同步更新**：`f` 或 `sync`（使用 Git Town）

### JJ
1. **创建新改动**：`n` 或 `nt`（从 trunk）
2. **提交改动**：`ci` 或 `cm "message"`
3. **重组历史**：`sq`（合并）、`sp`（拆分）、`rb`（rebase）
4. **同步远程**：`f`（获取并 rebase）、`ps`（推送）
5. **分支管理**：使用书签（`bs`、`bd`、`bl`）而非传统分支

## 注意事项

- Git Town 命令需要安装 [git-town](https://www.git-town.com/)
- PR 相关命令需要安装 [GitHub CLI](https://cli.github.com/)
- JJ 的一些命令使用了 bash，需要 bash 环境
- 部分 alias 包含交互式操作，不适合脚本使用
