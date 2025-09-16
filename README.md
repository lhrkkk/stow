# 新机器部署与使用指南（macOS + zsh + GNU Stow）

> 约定与前提
>
> - 操作系统：macOS，默认 shell：zsh
> - STOW_DIR：`$HOME/_env/stow`，TARGET：`$HOME`
> - 默认包：`mac-home`
> - 辅助脚本：`$HOME/_env/stow/mac-home/.local/bin/stowx`（stow 后会链接到 `$HOME/.local/bin/stowx`）
> - 强提醒：所有示例命令前面“刻意”留有一个空格，避免写入 shell 历史（遵循你的偏好与规则）
>
> 参考规则：详见 `mac-home/WARP.md` 与根目录 `STOW.md`

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

## 2. 首次链接（推荐先预览，再执行）

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

## 3. 常用工作流（stowx 优先）

- 预览：
  
  ```sh
   stowx preview
  ```

- 应用：
  
  ```sh
   stowx apply
  ```

- 列出包：
  
  ```sh
   stowx list
  ```

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

> 说明：`stowx` 为你在 `mac-home` 包内维护的辅助脚本，底层仍是 GNU Stow。习惯是“先预览，再执行”。

---

## 4. 收编（adopt）与覆盖式部署（谨慎）

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

## 5. 抓取（grab）：把散落文件归入包

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
   stowx grab -C -p mac-home ./WARP.md ./dir/file.txt
  ```

- 干跑评估抓取：
  
  ```sh
   stowx -n grab -p mac-home ~/.config/karabiner
  ```

> 限制：被抓取路径必须位于 `$HOME` 之下；否则会跳过并提示。

---

## 6. Zsh 补全（Git/JJ 分组版）

- 说明文档：`mac-home/.config/zsh/README.completion.md`
- 功能要点：
  - Git/JJ 别名按 8 个任务域分组展示（可选隐藏 Git 系统命令组）
  - 分组顺序与候选顺序稳定一致（禁排序、单次发射）
  - 提供 `ftb-debug-on/off` 抓取本次补全的分组与候选，用于排错
- 入口：
  - Git：`mac-home/.config/zsh/git-completion-enhanced.zsh`
  - JJ：`mac-home/.config/zsh/jj-completion-enhanced.zsh`
  - fzf-tab/样式：`mac-home/.config/zsh/zshrc`
  - 加载方式：由 `mac-home/.config/zsh/lazyload.zsh` 懒加载（首次 Tab/首个提示符触发），不再在 zshrc 中直接 `source`
  
 > 打开文档查看 8 组分法、每条别名说明、调试与自定义方法。
 
 ---
 
 ### 附：mise 懒加载说明
 
 - 启动仅注入 shims：`$HOME/.local/share/mise/shims` 优先加入 PATH；其余按需。
 - Zsh/Bash：首次提示符执行一次 `eval "$(mise hook-env -q)"`，之后不再自动触发。
 - 目录切换后依赖 mise shims 正常工作；如需手动刷新，可执行：`eval "$(mise hook-env -q)"`。
 - 为确保能发现 `mise`，在 `~/.config/env/common/paths.zsh` 中提前注入 Homebrew 路径（Apple Silicon 与 Linuxbrew）。
 - 推荐保持此模式，通常比 `eval "$(mise activate zsh)"` 更轻量。
 
 ---

## 7. 验证与常见应用

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

## 8. 故障排查与回滚

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

## 9. 版本控制建议

- 小步提交：每次变更（尤其是 adopt/抓取）后，及时 `git add/commit`。
- 推送前再次 `stowx preview`，确保没有意外路径。
- 新机器首配：建议建立专门的分支或 tag 记录关键节点；如需“覆盖式部署”，务必先确认 HEAD 正确。

---

## 10. Warp 会话日志（可选）

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

## 11. 速查表

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

- 重链 / 取消 / 列表：
  
  ```sh
   stowx restow
   stowx unstow mac-home
   stowx list
  ```

---

> 备注
>
> - 所有命令示例均在前加空格，避免写入 shell 历史。
> - 更详细的 stow 说明与行为差异，请见本仓库根目录 `STOW.md` 与 `mac-home/WARP.md` 中“Stow 规则引用”章节。

---

## 12. Zim（zimfw）安装与初始化

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
