# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

- 本仓库为 macOS 下的个人配置集合（~/.config）。关键子模块包括：WezTerm 终端配置、Yazi 文件管理器配置与插件、tmux-powerline 状态栏脚本。不存在常规的“构建/测试”流程，主要是编辑配置并即时/快速验证。

一、常用命令与开发工作流

- WezTerm
  - 入口：wezterm 将自动热重载 ~/.config/wezterm/wezterm.lua；保存后立即生效。
  - 手动指定配置文件启动（用于快速对比/回归）：
    - wezterm start --config-file ~/.config/wezterm/wezterm.lua
  - 调试：
    - wezterm ls（检查会话/窗格），wezterm help

- Yazi（目录：~/.config/yazi）
  - 启动：yazi
  - 插件/主题依赖（package.toml）
    - 更新依赖：ya pack -u
    - 列出依赖：ya pack -l
  - 快速验证配置（TOML/键位）：Yazi 启动失败会给出报错定位；也可按需使用 taplo 校验 TOML（若已安装）：
    - taplo check ~/.config/yazi

- tmux-powerline（目录：~/.config/tmux/tmux-powerline）
  - 构建可选的本地小工具（二进制，位于 segments/）
    - make -C ~/.config/tmux/tmux-powerline/segments
    - 清理：make -C ~/.config/tmux/tmux-powerline/segments clean
  - 生成默认 rc 配置（首次或重置时）：
    - ~/.config/tmux/tmux-powerline/generate_rc.sh
    - 将生成的 ~/.tmux-powerlinerc.default 重命名为 ~/.tmux-powerlinerc 并按需编辑
  - 在 ~/.tmux.conf 中使用：
    - set -g status on
    - set -g status-left  "#(~/.config/tmux/tmux-powerline/powerline.sh left)"
    - set -g status-right "#(~/.config/tmux/tmux-powerline/powerline.sh right)"

二、代码/配置结构与高层架构

- WezTerm（~/.config/wezterm/wezterm.lua）
  - 主题：使用内置配色 "Selenized Light (Gogh)"，从内置 schemes 读取背景色 bg，并统一用于：
    - 标签栏（tab_bar）各状态背景色、标题栏（window_frame）的前/背景色。
    - 满足“浅色标题栏”的偏好；与用户规则一致（Command+W 关闭 pane 且带确认；Ctrl+Space/ Ctrl+V 垂直 50% 分割；Ctrl+S 下分 50%）。
  - 字体链：JetBrains Mono → MesloLGS Nerd Font Mono → Symbols Nerd Font Mono；字体大小 15。
  - 窗口装饰：INTEGRATED_BUTTONS|RESIZE；启用 fancy tab bar；不隐藏单 tab 的 tab bar。
  - 关键键位绑定（均在 wezterm.lua 内集中定义并返回 config）：
    - Cmd+w 仅关闭当前 pane（confirm=true）。
    - Ctrl+Space / Ctrl+v：向右 50% 垂直分割；Ctrl+s：向下 50% 水平分割。

- Yazi（~/.config/yazi）
  - init.lua：
    - 启用 yaziline（状态栏样式/颜色/文件名截断等）与 starship（指向 ~/.config/yazi/starship.toml）。
    - 启用 git 插件；通过 Status:children_add 动态展示文件拥有者/组信息（仅 Unix）。
    - yamb 书签插件配置（cli=fzf）。
  - keymap.toml：
    - 为管理器（mgr）和子视图（spot/tasks/pick/input/completion/help）定义了详细快捷键映射。
    - 集成外部工具：
      - shell --confirm --block lazygit（按 Ctrl+g 打开 Lazygit）。
      - 插件快捷操作：smart-enter、yamb（书签保存/跳转/删除）、compress（归档）。
      - 导航增强：fzf、zoxide、ripgrep 搜索，隐藏文件切换，Tab 管理等。
    - 针对工作区快速跳转（g f n/y/z 等）到常用配置目录（~/.config、~/.config/yazi、~/.config/zsh 等）。
  - yazi.toml：
    - 界面布局、排序、预览与打开规则，以及各类预览器（code/json/image/video/pdf/archive/font/empty 等）定义。
    - opener 定义 macOS 下使用 open，编辑默认使用 $EDITOR。
  - package.toml：
    - 插件/主题依赖清单：
      - 插件：yaziline、starship、yazi-rs 官方插件（git、smart-enter）、yamb、compress。
      - 主题风味（flavors）：catppuccin-latte、flexoki-light、rose-pine-dawn、kanagawa-lotus 等。
  - starship.toml：禁用了 aws/gcloud/lua 模块，避免额外噪音。

- tmux-powerline（~/.config/tmux/tmux-powerline）
  - powerline.sh：主入口脚本；加载 lib、配置与参数解析，依据 left/right 渲染状态栏；支持“静音”某一侧。
  - generate_rc.sh：生成默认配置文件流程；用于初始化 ~/.tmux-powerlinerc。
  - segments/Makefile：可编译的段（如 xkb_layout.c、np_mpd）支持选择性构建；CC 自动选择 clang 或 gcc。
  - README.md（要点）：
    - 项目处于维护模式，但仍可作为轻量替代；依赖 bash、已打补丁的 Powerline 字体等。
    - tmux 配置片段与调试手段（bash -x powerline.sh left/right）。

三、与现有规则/工具的整合

- 用户规则（WezTerm 快捷键与浅色标题栏偏好）已在 wezterm.lua 内反映，无需额外操作。
- 若你在 Warp 中使用 WezTerm 配置为参考：
  - 本仓库的 WezTerm 配置与 Warp 并不冲突；Warp 作为终端环境可直接编辑这些文件，保存后 WezTerm 会自热重载（当使用 WezTerm 时）。

四、常见变更与快速验证建议

- 变更 WezTerm 配色/标题栏风格：编辑 ~/.config/wezterm/wezterm.lua 的 color_scheme 或 window_frame；保存后 WezTerm 自动重载。
- 增加/调整 Yazi 快捷键或插件：
  - 修改 keymap.toml / package.toml / init.lua；执行 ya pack -u 同步依赖；yazi 启动进行行为验证。
- tmux-powerline：
  - 新增/调整段：在 segments/ 内添加脚本或 C 源，必要时 make 重新构建；刷新 tmux 或 source-file 以应用。

五、已存在文件改进建议（若适用）

- 目前仓库未检测到已有 WARP.md；本文件为首次创建版本。
- 建议后续补充：
  - 若存在 ~/.tmux.conf 中与 powerline 集成的实际片段，可纳入本文件“示例片段”便于复制粘贴。
  - 若后续添加 Neovim 配置（~/.config/nvim），建议在此补充其插件管理器、启动/诊断命令与关键模块分层说明。

六、Stow 规则引用

- 规则文件路径：/Users/lhr/_env/stow/STOW.md
- 摘要：使用 GNU Stow 管理 dotfiles，STOW_DIR=$HOME/_env/stow，TARGET=$HOME，默认包 mac-home；提供辅助脚本 ~/.local/bin/stowx，支持 preview/apply/adopt/grab/unstow/restow/list。
- 快速命令：
  -  stowx preview      （等价: stow -nvt "$HOME" -d "$HOME/_env/stow" -S mac-home）
  -  stowx apply        （等价: stow -vt  "$HOME" -d "$HOME/_env/stow" -S mac-home）
  -  stowx adopt -y     （等价: stow -vt  "$HOME" -d "$HOME/_env/stow" -S --adopt mac-home）
  -  stowx grab -p mac-home <路径>
- 代理注意：命令前加空格避免写入历史；adopt/覆盖操作须确认；优先先预览再 apply。

