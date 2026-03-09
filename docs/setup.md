# 新机器部署与使用指南（macOS + zsh + GNU Stow）

> 约定与前提
>
> - 操作系统：macOS，默认 shell：zsh
> - STOW_DIR：`$HOME/_env/stow`，TARGET：`$HOME`
> - 默认包：`mac-home`
> - 辅助脚本：`$HOME/_env/stow/mac-home/.local/bin/stowx`（stow 后会链接到 `$HOME/.local/bin/stowx`）
> - 强提醒：所有示例命令前面“刻意”留有一个空格，避免写入 shell 历史（遵循你的偏好与规则）
>
> 参考规则：详见 [Warp 工作流说明](./warp.md) 与根目录 [`STOW.md`](../STOW.md)

---

## 0. 最低准备

- 安装 Xcode Command Line Tools（若未安装）
  
  ```sh
   xcode-select --install
  ```

- 安装 Homebrew（若未安装）
  
  ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- 安装必需工具（git、stow 等）
  
  ```sh
   brew update && brew install git stow
  ```

> 提示：若你使用企业代理或自建镜像，请按需替换下载源。

---

## 1. 获取仓库至固定路径

- 若尚未创建目录：
  
  ```sh
   mkdir -p "$HOME/_env"
  ```

- 克隆仓库到 `$HOME/_env/stow`
  
  ```sh
   git clone {{DOTFILES_REPO_URL}} "$HOME/_env/stow"
  ```

> 将 `{{DOTFILES_REPO_URL}}` 替换为你的远程仓库地址（例如 `git@github.com:you/dotfiles.git`）。

---

## 2. 一键 bootstrap（推荐）

仓库根目录提供了一个 `bootstrap.sh`，用于串联“安装前置依赖 + Brewfile + stow 部署”。
脚本会按平台自动选择 `mac-home/Brewfile`（macOS）或 `mac-home/Brewfile_linux`（Linux）。

- 首次安装：
  
  ```sh
   "$HOME/_env/stow/bootstrap.sh"
  ```

- 如需显式包含主机模块：
  
  ```sh
   "$HOME/_env/stow/bootstrap.sh" --host
  ```

- 后续更新（`git pull --ff-only` + `brew update` + `brew bundle` + `stowx restow`）：
  
  ```sh
   "$HOME/_env/stow/bootstrap.sh" update
  ```

- 若仓库有本地改动，只想跳过 `git pull` 继续更新其余部分：
  
  ```sh
   "$HOME/_env/stow/bootstrap.sh" update --allow-dirty
  ```

- 若你只想把当前仓库部署到当前机器，使用更轻量的 `deploy.sh`：
  
  ```sh
   "$HOME/_env/stow/deploy.sh"
  ```

- 若部署时也要同步 Homebrew：
  
  ```sh
   "$HOME/_env/stow/deploy.sh" --with-brew
  ```

说明：

- 默认会自动检测 `hosts/$(hostname)`；存在则一并 `apply/restow`，不存在则跳过。
- `update` 在仓库工作区不干净时会中止，除非显式传 `--allow-dirty`。
- `--skip-brew`、`--skip-stow`、`--skip-pull` 可用于局部执行。
- `deploy.sh` 默认等价于 `bootstrap.sh update --skip-brew`；`deploy.sh apply` 则等价于 `bootstrap.sh bootstrap --skip-brew`。

---

## 3. 首次链接（手动流程：推荐先预览，再执行）

无需提前把 `stowx` 加入 PATH，可直接通过仓库内路径调用。

- 预览将创建/变更的符号链接（不执行）：
  
  ```sh
   "$HOME/_env/stow/mac-home/.local/bin/stowx" preview
  ```

- 确认输出无误后，执行链接：
  
  ```sh
   "$HOME/_env/stow/mac-home/.local/bin/stowx" apply
  ```

- 可选：将 `$HOME/.local/bin` 加入 PATH（通常 `.zshrc` 已内置；若未生效可手动添加并重载）：
  
  ```sh
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" && exec zsh
  ```

> WezTerm 配置会自动热重载；Yazi 直接运行验证；tmux-powerline 可 `source`/reload 生效。

---

## 4. 常用工作流（stowx 优先）

- 预览：
  
  ```sh
   stowx preview
  ```

- 应用：
  
  ```sh
   stowx apply
  ```

- 自动（基础包 + 主机包，按需覆盖；支持 -n 干跑）：
  
  ```sh
   stowx auto
  ```

- 列出包：
  
  ```sh
   stowx list
  ```

  输出中会把 `hosts/`、`mods/` 下的一级子目录缩进列出，方便直接查看主机或模块包。

- 重链（刷新所有链接）：
  
  ```sh
   stowx restow
  ```

- 取消某包链接：
  
  ```sh
   stowx unstow mac-home
  ```

- 指定多个包：
  
  ```sh
   stowx apply -p mac-home -p another
  ```

- 任意命令 dry-run：
  
  ```sh
   stowx apply -n
  ```

- 主机特定模块：
  
  ```sh
   stowx apply --host
  ```

> 说明：`stowx` 为你在 `mac-home` 包内维护的辅助脚本，底层仍是 GNU Stow。习惯是“先预览，再执行”。
> 首次运行会在 `$STOW_DIR/.stow-global-ignore` 写入常见忽略规则（`.DS_Store`、临时目录、嵌套插件仓库等），避免把这些文件链接回家目录。

---

## 5. 收编（adopt）与覆盖式部署（谨慎）

当目标路径下已有同名“非链接”文件/目录时，会产生冲突。解决思路：

- 先评估“收编”影响（dry-run）：
  
  ```sh
   stowx preview -- --adopt
  ```

- 仅收编（把目标文件移动进包，然后创建链接）：
  
  ```sh
   stowx adopt -y
  ```

- 覆盖式部署（收编后再恢复到仓库 HEAD，以仓库版本覆盖本机现有文件；高风险，需确认）：
  
  ```sh
   stowx adopt -y -r   # 等价 --restore
  ```

- 另一种“覆盖式”工作流（与 Warp Drive 工作流 A-3 对应，结果一致）：
  
  ```sh
   stow -vt "$HOME" -d "$HOME/_env/stow" --adopt mac-home
   git -C "$HOME/_env/stow/mac-home" restore .
  ```

> 建议：在进行 adopt 或覆盖之前，确保仓库工作区干净（已提交），这样更易回滚。

---

## 6. 抓取（grab）：把散落文件归入包

当你在 `$HOME` 下新增/修改了零散配置，希望纳入 `mac-home` 包进行统一管理：

- 抓取单个文件：
  
  ```sh
   stowx grab -p mac-home ~/.config/wezterm/wezterm.lua
  ```

- 抓取多个路径：
  
  ```sh
   stowx grab -p mac-home ~/.zshrc ~/.gitconfig
  ```

- 使用相对路径（默认相对 `$HOME`）：
  
  ```sh
   stowx grab -p mac-home .ssh/config
  ```

- 以当前目录为相对基准：
  
  ```sh
   stowx grab -C -p mac-home ./docs/warp.md ./dir/file.txt
  ```

- 干跑评估抓取：
  
  ```sh
   stowx -n grab -p mac-home ~/.config/karabiner
  ```

- 抓取主机定制：
  
  ```sh
   stowx grab ~/.config/wezterm/wezterm.lua --host
  ```

> 限制：被抓取路径必须位于 `$HOME` 之下；否则会跳过并提示。

---

## 7. 主机特定模块（`hosts/<hostname>`）

当某台机器需要额外配置时，可在 `$STOW_DIR/hosts/<hostname>` 下维护主机专属模块：

- `stowx preview --host`、`stowx apply --host` 会在默认的 `mac-home` 基础上追加 `hosts/<hostname>`（`--host <name>` 可显式指定）。
- `stowx grab --host` 会把路径抓取到 `hosts/<hostname>`，首次使用时若目录不存在会自动创建。
- 只部署主机模块时，可直接指定包名：`stowx apply hosts/<hostname>` 或 `stowx apply -p hosts/<hostname>`。
- `stowx --host` 默认读取 `$(hostname)`；若需抓取同时传参，可写为 `stowx grab --host $(hostname) <path>` 或将 `--host` 放在参数末尾。
- `hosts/<hostname>` 目录不存在时，`--host` 会忽略该模块并输出提示，不影响其它包部署。
- `.stow-global-ignore` 若不存在会自动创建，默认忽略 `.DS_Store`、缓存目录、内嵌插件仓库等常见噪音；首次触发主机模块时，也会为 `hosts/<hostname>` 写入 `.stow-local-ignore`，便于局部定制忽略。

> 与 `mac-home` 同步维护主机模块，便于迁移到新机器时快速复用专属配置。

---

## 8. 冲突解析（--force：override/defer/ignore/adopt）

当目标路径已存在同名文件/目录时，stow 会报告冲突。stowx 提供统一的冲突解析：

- 交互式选择（推荐）：
  
  ```sh
   stowx apply --host --force
  ```
  
  - o=override：删除目标后接管（等价“覆盖”）；实现为 rm -rf 目标 + 追加 `--override '^相对路径$'`
  - d=defer：
    - 若是目录：追加 `--defer '^目录$'`，推迟处理父目录，利于目录折叠
    - 若是文件：追加 `--ignore '^文件$'`，稳定跳过该文件
  - q=quit：中止
  - a=adopt：逐文件“收编”（把 `$HOME` 下现有文件/目录移动到包内对应路径，然后继续 stow 建立链接）
    - 目标为符号链接时 adopt 语义不明确，自动退化为 override 接管
    - 包内已存在同名且你拒绝覆盖时，会为该路径追加 `--ignore`，避免后续 stow 再次因该路径中止

- 非交互默认覆盖（可配合 --defer 指定跳过项）：
  
  ```sh
   stowx apply --host --force -y --defer '^\.zshrc$' --defer '^\.config$'
  ```
  
  - .zshrc（文件）→ ignore；.config（目录）→ defer；其它路径默认覆盖

- restow 也支持同样的冲突解析：
  
  ```sh
   stowx restow --force -y
  ```

说明与注意
- 仅使用 GNU Stow 的 `--override` 无法直接覆盖“not owned by stow”的现有目标，因此 override 分支会先删除目标再链接。
- `--defer` 适合目录顺序控制（触发目录折叠）；对“文件级 not owned”基本无效，故文件使用 `--ignore` 跳过更稳妥。
- 所有删除操作在 `-n/--dry-run` 下仅打印 DRY-RUN 日志，不会修改文件。

## 9. SSH 节点清单（`nodes`）

为便于统一管理“登录过的远程节点”，仓库内提供了一个轻量工具：

- 脚本位置：`mac-home/.local/bin/nodes`
- 主机默认数据目录：`hosts/<hostname>/.config/nodes`
- 文件约定：
  - `nodes.tsv`：手工维护的稳定节点/别名
  - `history.tsv`：`nodes scan-history` 从 shell 历史重建的结果
- 读取优先级：`nodes.tsv` 优先于 `history.tsv`，避免重扫历史时覆盖手工条目

常用命令：

```sh
 nodes scan-history
 nodes scan-history --collapse-host
 nodes list
 nodes show <alias>
 nodes ssh <alias>
 nodes render-ssh-config
```

说明：

- `scan-history` 会扫描 `~/.zsh_history`、`~/.bash_history`、`~/.zhistory` 中的 `ssh/scp/sftp/rsync/mosh` 目标，并写入 `history.tsv`。
- 默认会保留有意义的 `host/user/port` 变体，只做轻量归一化：默认端口 `22` 会折叠为默认端口；同一主机若已存在明确用户，则匿名条目会被丢弃。
- 若你只想保留每台机器一个“主入口”，可显式使用 `nodes scan-history --collapse-host`；它会按 host 压缩，并优先挑选明确用户、出现次数更高的那条。
- `render-ssh-config` 默认生成 `nodes.generated.conf`；若你希望通过 `ssh <alias>` 直接使用这些别名，请在主 `~/.ssh/config` 中显式 `Include` 对应生成文件。
- 建议把稳定命名、标签、端口修正，以及同机多账号/多端口等特殊入口放入 `nodes.tsv`；把“自动发现的主入口”交给 `history.tsv`。

## 10. Zsh 补全（Git/JJ 分组版 + report-kit）

- 说明文档：`mac-home/.config/zsh/README.completion.md`
- 功能要点：
  - Git/JJ 别名按 8 个任务域分组展示（可选隐藏 Git 系统命令组）
  - 分组顺序与候选顺序稳定一致（禁排序、单次发射）
  - 提供 `ftb-debug-on/off` 抓取本次补全的分组与候选，用于排错
  - report-kit CLI 补全按需注册，首次 Tab 延后执行 `report-kit completion zsh --fallback`；为配合 fzf-tab，会把候选改写成 `命令 - 描述`，在弹窗里也能看到说明；`rk` 等 alias 会在懒加载阶段调用 `report-kit completion zsh --fallback --prog <alias>` 生成同款脚本并修正 fallback 条件（可设 `REPORT_KIT_COMPLETION_FALLBACK=0` 禁用）
  - stowx CLI 补全按需注册，提供子命令/包名候选（解析 STOW_DIR 目录）
- 入口：
  - Git：`mac-home/.config/zsh/git-completion-enhanced.zsh`
  - JJ：`mac-home/.config/zsh/jj-completion-enhanced.zsh`
  - report-kit：`mac-home/.config/zsh/report-kit-completion.zsh`
  - stowx：`mac-home/.config/zsh/stowx-completion.zsh`
  - fzf-tab/样式：`mac-home/.config/zsh/zstyles.zsh`（与 `~/.config/zsh/fzf.zsh` 共用配色 + ANSI；首次 Tab/`ctrl+R`/直接 `fzf` 时若存在 `~/.local/bin/check_term_theme.py` 会自动探测浅/深色，任何时候执行 `ami-fzf-apply-theme dark|light` 都会同步刷新 fzf 与 fzf-tab）
  - zoxide 集成：`zi` 命令（交互式目录选择）首次触发时自动设置 fzf 主题，确保候选列表颜色与系统主题保持一致
  - g 函数补全：`g` 命令（git 别名）现在支持完整的 git 子命令和参数补全
  - Git 别名显示参数：
    - `AMI_GIT_ALIAS_EXPANSION=full|auto|none`（默认 `full`）
    - `AMI_GIT_ALIAS_EXP_WIDTH=64`（展开式截断宽度）
    - `AMI_GIT_ALIAS_SEP1` / `AMI_GIT_ALIAS_SEP2`（分隔符，默认 ` -- ` / ` | `）
 - 加载方式：由 `mac-home/.config/zsh/lazyload.zsh` 懒加载（首次 Tab/首个提示符触发），不再在 zshrc 中直接 `source`
  - 调优：可打开一次性计时打印，用于衡量优化效果：
    
    ```zsh
    AMI_TIMING=1 exec zsh -l  # 打印“首个提示符 / 首次 Tab 初始化”耗时
    ```
  
 > 打开文档查看 8 组分法、每条别名说明、调试与自定义方法。
 
 ---
 
 ### 附：mise 懒加载说明
 
 - 启动仅注入 shims：`$HOME/.local/share/mise/shims` 优先加入 PATH；其余按需。
 - Zsh/Bash：首次提示符执行一次 `eval "$(mise hook-env -q)"`，之后不再自动触发。
 - 目录切换后依赖 mise shims 正常工作；如需手动刷新，可执行：`eval "$(mise hook-env -q)"`。
 - 为确保能发现 `mise`，在 `~/.config/env/common/paths.zsh` 中提前注入 Homebrew 路径（Apple Silicon 与 Linuxbrew）。
 - 推荐保持此模式，通常比 `eval "$(mise activate zsh)"` 更轻量。
 
 ---

## 10. AI 提交助手（git / jj）

- 工具：`git-commit-ai`、`jj-commit-ai` 默认调用 **Codex** 后端，模型为 `gpt-5`。
- 切换后端：`--api gemini` 可改用 Gemini；也可通过 `GIT_COMMIT_AI_BACKEND` / `JJ_COMMIT_AI_BACKEND` 环境变量。
- 推理强度：`--reasoning-effort`, `-r`（或环境变量 `GIT_COMMIT_AI_REASONING_EFFORT`、`JJ_COMMIT_AI_REASONING_EFFORT`）会透传为 `model_reasoning_effort`，可选 `minimal / low / medium / high`（默认 `minimal`）。
- 大 diff 处理：若 Codex 调用失败且检测到可能超限，`jj-commit-ai` 会自动缩小 `--max-bytes` 并重试（默认最多 3 次，最小 8000 字节；可用 `JJ_COMMIT_AI_TRUNCATE_RETRY_MAX`、`JJ_COMMIT_AI_TRUNCATE_RETRY_MIN_BYTES` 调整）。
- JJ 支持：使用 `--describe` 以 `jj describe -m` 应用生成信息（替代 `jj commit`）；
  若要针对非工作副本的修订，可直接加 `--rev <rev>`（隐式启用 `--describe`）。
  若需要批量处理描述为空但有改动的提交，可用 `jj-commit-ai fill-empty`。
- 语言兜底：若偏好中文但 Codex 仅返回英文，脚本会打印原始结果并回退到本地摘要；设置 `GIT_COMMIT_AI_ALLOW_ENGLISH=1`（或 JJ 对应变量）可放行英文输出。
- 常见示例：
  
  ```sh
   git-commit-ai --preview               # 默认 Codex + gpt-5（-r minimal）
   git-commit-ai --api gemini --preview  # 切换到 Gemini
   git-commit-ai --api codex -r medium   # 指定推理强度
   JJ_COMMIT_AI_ALLOW_ENGLISH=1 jj-commit-ai --api codex --preview
   jj-commit-ai --describe --preview     # 仅更新当前变更的描述（jj describe -m）
   jj-commit-ai --rev @~1 --preview      # 针对指定修订生成描述
   jj-commit-ai fill-empty --dry-run     # 预览所有描述为空但有 diff 的提交
   jj-commit-ai fill-empty -y            # 批量填充并跳过确认
  ```

---

## 11. 验证与常见应用

- WezTerm：保存 `~/.config/wezterm/wezterm.lua` 后自动热重载；偏好“浅色标题栏”已在配置中处理。
- Yazi：
  
  ```sh
   yazi
  ```
  
  插件依赖同步：
  
  ```sh
   ya pack -u
  ```

- tmux-powerline：首次可生成默认 rc 并应用：
  
  ```sh
   ~/.config/tmux/tmux-powerline/generate_rc.sh
  ```
  
  在 `~/.tmux.conf` 中使用：
  
  ```tmux
   set -g status on
   set -g status-left  "#(~/.config/tmux/tmux-powerline/powerline.sh left)"
   set -g status-right "#(~/.config/tmux/tmux-powerline/powerline.sh right)"
  ```

---

## 12. 故障排查与回滚

- 预览输出包含 LINK/CONFLICT/REMOVE 等关键字时，请先停止执行并确认方案。
- 冲突（目标存在非链接同名文件）：优先选择 adopt；若不想保留现状，可走“覆盖式部署”（谨慎）。
- 回滚：
  - 链接层面：
    
    ```sh
     stowx unstow mac-home
    ```
  
  - 仓库工作区：
    
    ```sh
     git -C "$HOME/_env/stow" restore .
    ```
  
  - 重新链接：
    
    ```sh
     stowx restow
    ```

---

## 13. 版本控制建议

- 小步提交：每次变更（尤其是 adopt/抓取）后，及时 `git add/commit`。
- 推送前再次 `stowx preview`，确保没有意外路径。
- 新机器首配：建议建立专门的分支或 tag 记录关键节点；如需“覆盖式部署”，务必先确认 HEAD 正确。

---

## 14. Warp 会话日志（可选）

若你在 Warp 中使用日志脚本（例如 `warp-log` 系列），可参考：

- 追加或新建：
  
  ```sh
   warp-log append -t "标题" -m "本次摘要"
  ```

- 打开目录 / 最新：
  
  ```sh
   warp-log open
   warp-log latest
  ```

> 约束：该工具仅读写 `$HOME/@log/warp`，并按会话 ID 归档增量内容。

---

## 15. 速查表

- 预览 → 应用：
  
  ```sh
   stowx preview
   stowx apply
  ```

- 收编（仅收编 / 覆盖式）：
  
  ```sh
   stowx preview -- --adopt
   stowx adopt -y
   stowx adopt -y -r
  ```

- 抓取：
  
  ```sh
   stowx grab -p mac-home <路径>
  ```

- 放回（putback：从包复制到原路径，不移动）：
  
  ```sh
   stowx putback -p mac-home <路径>
  ```
  
  - 相对路径默认相对 `$HOME`；可用 `-C` 改为相对当前目录
  - 也可配合 `--host` 或 `-p hosts/<hostname>` 指定主机包
  - 仅当目标不存在或是“符号链接”时执行；若希望覆盖已存在的普通文件，可加 `--allow-non-symlink`

- 重链 / 取消 / 列表：
  
  ```sh
   stowx restow
   stowx unstow mac-home
   stowx list
  ```

- 环境刷新：
  
  ```sh
   mise-refresh   # 手动重跑 mise hook-env 并刷新命令缓存
   env-rehash     # 仅刷新命令缓存（zsh/bash 通用）
   brew-env       # 手动 eval "$(brew shellenv)" 并刷新缓存
  ```

---

> 备注
>
> - 所有命令示例均在前加空格，避免写入 shell 历史。
- 更详细的 stow 说明与行为差异，请见本仓库根目录 [`STOW.md`](../STOW.md) 与 [Warp 工作流说明](./warp.md) 中“Stow 规则引用”章节。

---

## 16. Zim（zimfw）安装与初始化

本仓库使用 Zim（zimfw）作为 zsh 框架；已在 `mac-home/.config/zsh/plugins.zsh` 中内置“首次自动安装”逻辑：首次启动 zsh 时若未检测到 `~/.zim`，会自动下载安装，并把 `~/.zimrc` 链接到仓库内的 `~/.config/zsh/zimrc`。

- 你也可以手动提前安装（效果等同）：
  
  ```sh
   curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
   rm -f ~/.zimrc
   ln -s ~/.config/zsh/zimrc ~/.zimrc
   zimfw install
  ```

- 常用命令：
  
  ```sh
   zimfw update      # 拉取并更新模块
   zimfw compile -q  # 预编译以加速启动
   recompile-zsh     # 本仓库提供的小工具，统一预编译 zsh/补全缓存
  ```

- 验证：
  - 新开一个 zsh，确认提示符与补全可用；
  - 如遇问题，可执行：
    
    ```sh
     zimfw doctor
    ```

---

## 17. Git/JJ 工作区工作流（wo / ws / wm / wsa / wma / wmsa）

- 目录与约定
  - Git 工作区：`$REPO/.jj/git-1|git-2|git-3`
  - JJ 工作区：`$REPO/.jj/workspace-one|two|three`
  - 统一“返回根目录”函数：`wo`（zsh 函数，进入 `wo1/wo2/wo3` 时会导出 `WO_RETURN_DIR`，在子 shell 内执行 `wo` 可直接回到仓库根）

- 进入工作区（带存在性校验）
  - Git：`git wo1|wo2|wo3`（不存在时提示一次并返回非 0；无参进入登录 shell，有参在该目录执行）
  - JJ：`jj wo1|wo2|wo3`（不存在时提示一次并返回 0 跳过；无参进入登录 shell，有参在该目录执行）
  - 统一：`git wo` / `jj wo` / `wo` 在根目录开登录 shell；传参则在根目录执行参数命令

- 同步与合并（输出风格统一）
  - 成功：仅显示成功结果（不带冒号）
    - 例（JJ 同步某分支）：`[ws1] default <- one@: a1b2c3 Update deps`
    - 例（JJ 合并标记）：`[wm1] default <- one: a1b2c3 Update deps`
    - 例（Git 合并标记）：`[wm1] main <- git-1`
  - 失败：仅提示失败原因，使用冒号
    - 例：`[wm2] fail: Rebase aborted: conflicts ...`
    - JJ：`skip: head missing`
    - Git：`skip: missing workspace`

- 组合命令（含工具前缀提示）
  - JJ：
    - `jj wmsa` →
      - `[wmsa] jj: 标记+合并+同步所有分支`
      - `[wseta] jj 标记 one/two/three：`
      - `[wset1] one <- one@-: …` / `[wset2] two <- two@-: …` / `[wset3] three <- three@-: …`
      - `[wma] jj 合并所有分支：`
      - `[wm1] default <- one: …` / `[wm2] default <- two: …` / `[wm3] skip: bookmark missing`
      - `[wsa] jj 同步所有分支：`
      - `[ws1] default <- one@: …` / `[ws2] default <- two@: …` / `[ws3] skip: head missing`
      - `jj n default`（静默执行，等同 `jj new default`）：把默认工作区重新挂到最新 `default` 节点
    - `jj wmsap`（“@ 版”，不刷新 one/two/three 书签）→
      - `[wmsap] jj: wmap + wsap`
      - `[wmap] jj 合并所有 @- 分支：`
      - `[wm1p] default <- one@-` / `[wm2p] default <- two@-` / `[wm3p] skip: head missing`
      - `[wsap] jj 同步所有分支(@ 版)：`
      - `[ws1p] default <- one@` / `[ws2p] default <- two@` / `[ws3p] skip: head missing`
      - `jj n default`（静默执行，等同 `jj new default`）：同样把默认工作区挂回最新 `default`
  - Git：
    - `git wmsa` →
      - `[wmsa] git: wma + wsa: 合并和同步所有分支`
      - `[wma] git 合并所有分支：`
      - `[wm1] main <- git-1` / `[wm2] main <- git-2` / `[wm3] skip: missing workspace`
      - `[wsa] git 同步所有分支：`
      - `[ws1] rebase main` / `[ws2] rebase main` / `[ws3] skip: missing workspace`

- 其它
  - JJ 状态速览：`jj wsl`（输出 one/two/three 的目录与 head 状态）
  - `wmsa` 会自动执行 `wseta`，确保 `one|two|three` 书签与 `@-` 对齐；`wmsap` 则保持原样，仅推进 `@`/`@-`。
  - Git/JJ 的 `ws*`/`wm*` 系列均统一使用“成功仅输出结果、失败输出首行原因、缺失 skip”的风格。
