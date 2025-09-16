# AGENTS.md（仓库协作与约定）

本文件为本仓库的“代理/自动化助手”工作指南，适用于整个仓库（自根目录起的所有子目录）。

目标

- 保持 zsh 启动快速稳定，所有“重活”通过懒加载完成；
- 保持工具链（mise/direnv/conda/brew 等）按需生效；
- 文档、脚本与行为一致，便于维护与迁移。

约定与关键规则

1) Zsh 初始化与补全
- 不要在 `~/.config/zsh/zshrc` 直接 `source` 重型补全脚本；统一通过 `~/.config/zsh/lazyload.zsh` 懒加载。
- `lazyload.zsh` 职责：
  - 捕获启动期 `compdef`；首个 Tab/首个提示符前执行 `_lazy_compinit_run`；
  - 在 `compinit` 后调用各模块一次性的 `__ami_after_compinit` 钩子；
  - 通过 `__ami_source_completions_once` 在需要时 `source`：
    - `~/.config/zsh/git-completion-enhanced.zsh`
    - `~/.config/zsh/jj-completion-enhanced.zsh`
- 若新增补全或模块，需要：
  - 将“生效动作”封装到 `__ami_after_compinit` 中；
  - 仅在 lazy 触发点加载脚本，避免启动时间倒退。

2) mise/direnv 等环境钩子（Bash/Zsh 通用）
- 统一在 `~/.config/env/common/lazy.zsh` 中配置；
- mise：
  - 仅将 shims 提前加入 PATH：`$HOME/.local/share/mise/shims`；
  - Zsh/Bash 在首次提示符时执行一次 `eval "$(mise hook-env -q)"`，之后不再自动触发；
  - 保留常见路径兜底：若未找到 `mise`，尝试加入 `/opt/homebrew/bin`、`/home/linuxbrew/.linuxbrew/bin`、`$HOME/.local/bin`；
  - 不要使用 `eval "$(mise activate zsh)"` 覆盖现有策略。
- direnv：首次提示符初始化一次并同步当前目录环境（随后由 direnv 自身的钩子接管）。
- zoxide：首次提示符初始化一次（若 `ZOXIDE_USE_CD=1` 则使用 `--cmd cd` 覆盖 `cd`）。
- 其它工具（conda/brew/x-cmd）：首次调用时再初始化。

3) PATH 与 Homebrew 提前注入
- 在 `~/.config/env/common/paths.zsh` 中优先注入 Homebrew 路径（如存在）：
  - `/opt/homebrew/bin /opt/homebrew/sbin`（Apple Silicon）
  - `/home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin`（Linuxbrew）
- 不要在其它文件重复注入同样路径，以免 PATH 膨胀与顺序不稳。

4) 文件组织与可维护性
- 自定义函数建议放在 `~/.config/zsh/functions`，使用 `autoload` 懒加载。
- 改动补全/懒加载行为时，请同步更新：
  - 根 `README.md` 的相关段落（Zsh 补全 / mise 附录）
  - `~/.config/zsh/README.completion.md`（加载方式/验证步骤）

5) 验证建议
- 新开一个 Login zsh：`exec zsh -l`；
- 首次 Tab 或首个提示符后：
  - `print -r -- $GIT_COMPLETION_ENHANCED` 应为 `1`；
  - `type -a mise` 能找到；含配置目录下 `mise current` 正确；
  - `bindkey '^I'` 确认 Tab 绑定；
  - `zstyle -L ':completion:*:*:git:*'` 检查样式是否生效。

如需偏离以上约定，请在 PR/commit 描述中说明动机与影响范围。
