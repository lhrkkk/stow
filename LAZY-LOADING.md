# 懒加载架构说明（Zsh + 工具链）

概览

- 目标：更快的启动时间、更稳定的补全顺序、按需初始化工具链。
- 两条主线：
  - Zsh 内部（补全/框架/主题）→ `~/.config/zsh/lazyload.zsh`
  - 外部工具/环境（mise/direnv 等）→ `~/.config/env/common/lazy.zsh`

文件职责

- `~/.config/zsh/lazyload.zsh`
- 捕获启动期 `compdef` 调用，避免未 `compinit` 前报错；
- 首次按 Tab 时执行 `_lazy_compinit_run` 初始化补全；
  - `compinit` 之后调用一次 `__ami_after_compinit`（由各模块提供）；
  - 懒加载 Git/JJ 增强补全：`__ami_source_completions_once` 首次按需 `source` 脚本；
  - 延后加载 Zim（prompt/autopair）并保持覆盖顺序。

- `~/.config/env/common/lazy.zsh`
  - mise：只把 shims 放 PATH；Zsh/Bash 在首次提示符时执行一次 `eval "$(mise hook-env -q)"`；
  - direnv：首次提示符初始化一次并同步当前目录环境（随后由 direnv 自身 hook 接管）；
  - zoxide：首次提示符初始化一次（从会话开始记录目录历史；`ZOXIDE_USE_CD=1` 时覆盖 `cd`）；
  - conda/brew/x-cmd：函数/命令首次调用时初始化；
  - 兜底：找不到 `mise` 时尝试注入常见 Homebrew/本地 bin 路径。

- `~/.config/env/common/paths.zsh`
  - 提前注入 Homebrew 二进制路径（Apple Silicon 与 Linuxbrew），确保 `mise` 等可发现。

触发点与时序

1) 启动：
   - PATH 注入（Homebrew/shims）→ 立即可发现 mise；
   - 检测当前/父目录是否有配置；若有则运行一次 hook-env；
   - 未执行 `compinit`，提示符尽快出现。

2) 首次 Tab：
   - 懒加载 Git/JJ 脚本；
   - 运行 `compinit`；
   - 执行各模块的 `__ami_after_compinit` 完成 compdef/样式挂接；
   - 延后加载 Zim 与主题。

3) 切目录：
   - 不自动触发 mise；依赖 shims 正常工作；如需刷新环境变量可手动运行 `eval "$(mise hook-env -q)"`。

如何新增“补全增强/插件”

- 不要在 `zshrc` 直接 `source` 重型脚本；
- 在脚本内提供一个 `__ami_after_compinit` 函数，完成 compdef 与样式设置；
- 将脚本加入 `__ami_source_completions_once`（仅加载一次）。

如何新增“工具/环境”

- 放入 `~/.config/env/common/lazy.zsh`；
- 优先使用：占位函数包装 + 首次调用初始化；
- 若需“基于目录持续更新”的外部工具，请使用其自带 hook（如 direnv 在 init 后会注册自身钩子）；对于仅需一次的初始化（如本仓库的 mise/direnv），使用一次性 `precmd` 更轻量。

验证步骤

```zsh
exec zsh -l
print -r -- $GIT_COMPLETION_ENHANCED   # 启动后应为空；触发 Tab/首个提示符后变为 1
print -r -- $JJ_COMPLETION_ENHANCED    # 首次 Tab 后应为 1，用于验证 JJ 补全已挂接
type -a mise                             # 能找到 mise
cd <含 .mise.toml 或 .tool-versions 的目录> && mise current
bindkey '^I'                             # 确认 Tab 绑定到 fzf-tab 流程
zstyle -L ':completion:*:*:git:*'        # 检查 sort false、group-order 等
```

调优与计时（可选）

```zsh
# 打印一次性时长：首个提示符、首次 Tab 初始化
AMI_TIMING=1 exec zsh -l
# 关闭（默认即为关闭）
AMI_TIMING=0 exec zsh -l
```

常见问题与排查

- 启动就报 compdef 错：未走懒加载流程；确认 `lazyload.zsh` 是否被 `zshrc` 引入，且未提前 `compinit`。
- 找不到 mise：确认 `paths.zsh` 已把 Homebrew 路径提前注入；`type -a mise` 验证。
- 补全顺序错乱：检查是否有其它插件/脚本在 git/jj 上设置 tag-order/group-order；可先 `zstyle -d ...` 清理后再试。

最佳实践（Do/Don’t）

- Do：使用 `autoload` 管理 `~/.config/zsh/functions` 下的函数；
- Do：把“生效动作”挂到 `__ami_after_compinit`，由懒加载时机一次性触发；
- Do：对目录驱动的环境变更使用 `hook-env -q` 这种幂等/静默模式；
- Don’t：在 `zshrc` 直接 `source` 重型补全脚本；
- Don’t：到处重复注入同一 PATH；保持在 `paths.zsh` 集中维护。
