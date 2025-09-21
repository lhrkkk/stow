# GNU Stow 管理规则（macOS dotfiles）

一、目的与范围
- 使用 GNU Stow 管理 dotfiles，将包目录从 `$HOME/_env/stow` 链接到 `$HOME`。
- 适用环境：macOS、zsh。
- 命令执行规范：所有命令示例均故意以空格开头，避免写入 shell 历史。

二、目录与工具约定
- STOW_DIR：`$HOME/_env/stow`
- TARGET：`$HOME`
- 默认包：`mac-home`
- 辅助脚本：`~/.local/bin/stowx`（由 `mac-home` 包提供链接，源文件位于 `$HOME/_env/stow/mac-home/.local/bin/stowx`）
- 主机特定模块：位于 `$STOW_DIR/hosts/<hostname>`，配合 `stowx --host` 自动追加
- PATH 建议包含：`$HOME/.local/bin`
- 首次运行 `stowx` 会自动在 `$STOW_DIR/.stow-global-ignore` 写入默认忽略（`.DS_Store`、cache/tmp、嵌套插件仓库等）
  - 若首次使用主机模块，也会在 `hosts/<hostname>` 下生成 `.stow-local-ignore`，便于局部忽略噪音文件

三、常用工作流与命令
- 预览（dry-run + verbose，推荐先做）
  -  ` stowx preview`
- 应用（执行链接）
  -  ` stowx apply`
- 收编与覆盖（adopt，将未托管文件“收编”到包内后建立链接）
  -  仅收编（默认，不恢复工作区）：` stowx adopt -y`
  -  覆盖式部署（收编后恢复到 HEAD，谨慎）：` stowx adopt -y -r`（或 `--restore`）
  -  干跑评估收编影响：` stowx preview -- --adopt`
- 取消/重链
  -  ` stowx unstow mac-home`
  -  ` stowx restow`
- 列出包
  -  ` stowx list`
    - `hosts/`、`mods/` 会同时列出一级子目录，便于浏览主机与模块包
- 指定包与目标
  -  ` stowx apply -p mac-home -p another`
  -  ` stowx preview -d "$HOME/_env/stow" -t "$HOME"`
- 干跑任何命令
  -  ` stowx apply -n`
- 主机附加模块
  -  ` stowx apply --host`（默认当前 `hostname`，可用 `--host <name>` 指定）

四、抓取能力（grab）
- 功能：将 TARGET 范围内的文件/目录移动到指定包的对应相对路径下，并自动 `restow` 建立符号链接。
- 相对路径解析：
  - 默认：相对于 TARGET（即 `$HOME`）解析。
  - 可选：使用 `-C/--relative-to-cwd` 时，相对路径相对于当前目录（`$PWD`）解析（仍要求最终路径位于 TARGET 之下，否则跳过）。
- 用法示例：
  - 抓取单个文件：` stowx grab -p mac-home ~/.config/wezterm/wezterm.lua`
  - 抓取多个路径：` stowx grab -p mac-home ~/.zshrc ~/.gitconfig`
  - 使用相对路径（默认相对 TARGET=`$HOME`）：` stowx grab -p mac-home .ssh/config`
  - 使用当前目录相对路径：` stowx grab -C -p mac-home ./WARP.md ./dir/file.txt`
  - 干跑预览抓取：` stowx -n grab -p mac-home ~/.config/karabiner`
  - 同名目标存在时可用 `-y` 覆盖
- 主机定制：
  - ` stowx grab ~/.config/wezterm/wezterm.lua --host`（无参数默认当前 `hostname`；也可写为 `--host <name>`）
- 限制：被抓取路径必须位于 TARGET（默认 `$HOME`）之下；否则跳过并提示。
- 忽略文件：若 `$STOW_DIR/.stow-global-ignore` 不存在，`stowx` 会写入默认忽略规则，避免 `.DS_Store`、缓存目录等噪音被链接；可按需追加自定义模式。
  - 主机模块初次使用时会生成 `hosts/<hostname>/.stow-local-ignore`，默认忽略 `.DS_Store`、临时目录、嵌套插件仓库等，可自行扩展。

五、代理执行准则（Warp Agent 指南）
- 总原则
  - 优先使用 `stowx` 完成 stow 相关操作；先预览再执行。
  - 对 adopt、覆盖或删除等潜在破坏性操作，默认要求确认；仅在用户明确同意时继续。
  - 运行命令时一律在前面加空格，避免写入 shell 历史。
- 命令习惯
  - 小步修改、小步验证：先 ` stowx preview`，再 ` stowx apply`。
  - 预计需要“收编”现有文件时，先 ` stowx preview -- --adopt` 评估影响；
    - 仅收编：` stowx adopt -y`
    - 收编并覆盖到 HEAD：` stowx adopt -y -r`（或 `--restore`）
  - 需要把散落在 `$HOME` 下的单个文件/目录收编时，使用 ` stowx grab -p <包名> <路径>`。
- 冲突与安全
  - 遇到目标路径非链接且同名存在的冲突：优先提示用户选择 adopt 或手动清理。
  - adopt 前建议确保对应包仓库 clean（已提交），便于回滚。
- 验证
  - WezTerm 配置自动热重载；Yazi 直接运行验证；tmux-powerline 可 reload/source 生效。

六、问题诊断与回滚
- 预览输出中包含 LINK/CONFLICT/REMOVE 等关键字时，应先与用户确认再执行。
- 出现误操作时：
  - 对包仓库可用 `git restore .` 或 `git checkout -- <paths>` 回滚工作区；
  - 对已创建的链接可用 ` stowx unstow <包>` 撤销，再按需 `restow`。

七、快速速查
- 默认包 `mac-home`
  - 预览：` stowx preview`
  - 应用：` stowx apply`
  - 收编：` stowx grab -p mac-home <路径>` 或 ` stowx adopt -y`
  - 覆盖：` stowx adopt -y -r`（或 `--restore`）
  - 主机附加：` stowx apply --host`（追加 `hosts/<hostname>` 包）
