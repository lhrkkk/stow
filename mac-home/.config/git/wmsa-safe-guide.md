# git `wmsa` 安全使用说明

`git wmsa` 是对多工作区（`.jj/git-1|2|3`）的批量操作封装，用来快速完成“合并工作树分支到 main 并同步各工作区”的流程。本文梳理指令链路、前置检查、常见失败原因与恢复步骤，便于在复杂场景下安全使用。

## 指令链路概览

- `git wmsa`
  - 打印 `[wmsa] git: wma + wsa: 合并和同步所有分支`。
  - 顺序执行 `git wma` 与 `git wsa`（定义见 `mac-home/.config/git/config:223-237`）。
- `git wma`
  - 打印 `[wma] git 合并所有分支：`。
  - 依次运行 `git wm1`、`git wm2`、`git wm3`。
- `git wm{1,2,3}`
  - 校验对应工作区目录是否存在，若缺失输出 `skip`。
  - 若工作区正在 rebase（`rebase-merge`/`rebase-apply` 存在），先尝试 `git rebase --continue`。
  - 在工作区内执行 `git rebase main`，随后回到根仓库执行 `git rebase git-{N}` 把 `main` 快进到工作区对应分支。
- `git wsa`
  - 打印 `[wsa] git 同步所有分支：`。
  - 对三个工作区循环：若目录缺失则 `skip`，否则在工作区内执行 `git rebase --continue`（若必要）与 `git rebase main`。

## 运行前检查清单

1. **确认在 Git 仓库根目录执行**：`git rev-parse --show-toplevel` 应指向目标仓库；若处于工作区内部，可先运行 `git wo` 返回根目录。
2. **工作区存在**：`.jj/git-1|2|3` 目录需存在；若缺失可通过 `git wa1|wa2|wa3` 重新添加。
3. **工作区干净**：分别进入 `git wo1`/`wo2`/`wo3` 运行 `git status --short --branch`，确认无未提交改动或冲突。未提交改动会阻断 rebase，导致 `git wmsa` 报错。
4. **根仓库干净**：在主工作区执行 `git status --short --branch`，确保准备好接受 rebase 结果。
5. **确认分支指向**：`git branch --show-current` 在每个工作区都应指向 `git-1`/`git-2`/`git-3` 等预期分支，避免处于 detached HEAD。

## 常见失败情形与提示

| 环节 | 触发条件 | 典型提示 | 处理建议 |
| ---- | -------- | -------- | -------- |
| 启动 | 非 Git 仓库运行 | `fatal: not a git repository` | 切换到仓库根目录或正确工作区。|
| wmN | 工作区目录缺失 | `[wm1] skip: missing workspace`（或 `[wm3] skip: head missing`） | 使用 `git waN` 重建对应 worktree。|
| wmN | 工作区有未提交改动 | `error: cannot rebase: You have unstaged changes.` 或 `Please commit or stash them.` | 保存变更（commit/stash）或放弃改动，再重试。|
| wmN | rebase 冲突 | `error: could not apply ...` 或 `Resolve all conflicts manually` | 进入对应工作区，解决冲突后 `git rebase --continue`，确认成功再执行 `git wmsa`。|
| wmN | 根仓库 rebase 失败 | `[wm1] fail: ...` 首行显示 `cannot rebase: Your index contains uncommitted changes` 等 | 确认根仓库干净，必要时 stash/commit，再运行。|
| wsa | 工作区缺失 | `[wsa] -> [ws1] skip: missing workspace` | 属提醒，不影响其他工作区；若非预期需恢复目录。|
| wsa | 工作区已有待完成 rebase | `[wsa] -> [ws1] fail: could not apply ...` | 在工作区内完成 `git rebase --continue` 或 `git rebase --abort` 后再运行。|
| 任意 | 同步外部命令中断 | `[wma] git 合并所有分支：` 后未继续、shell 返回非 0 | 查看屏幕上最后一条失败消息，按“故障排查流程”处理。|

> 说明：若工作区正处于 detached HEAD，`git rebase main` 仍会执行，但 detached HEAD 上新增的提交不会自动回写到对应分支，`git rebase git-N` 也不会获取这些提交。请确保工作区始终附着在 `git-1`/`git-2`/`git-3` 分支上。

## 故障排查流程

1. **锁定失败步骤**：`git wmsa` 会立即打印首个失败命令的第一行输出（例如 `[wm2] fail: ...`），记录具体工作区编号。
2. **手动重放**：运行 `git wm2` 或展开为 `git -C .jj/git-2 rebase main`、`git rebase git-2` 查看完整错误信息。
3. **解决冲突**：进入相应工作区（`git wo2`）执行 `git status`，按 Git 标准流程解决冲突、`git add` 标记并 `git rebase --continue`。如需取消，改用 `git rebase --abort`。
4. **处理未提交改动**：若报 `unstaged changes` 或 `would be overwritten by checkout`，请 commit / stash / clean。本地临时修改不会被静默丢弃，除非手动使用 `--force`。确认工作区干净后再试。
5. **重新验证**：在受影响工作区先运行 `git wsN`（或手动 `git -C` 命令）确认通过，再运行 `git wmsa`。
6. **保持单线程**：避免并行在多个终端调用 `git wmsa` 或执行操作 `git rebase git-N`，否则可能出现 `fatal: update_ref failed for ref 'refs/heads/main': cannot lock ref` 等并发写冲突。

## 安全使用建议

- 在批量合并前，先运行 `git wsl`：它会报告每个 worktree 是否处于 REBASE 状态。
- 若只需同步单个工作区，可直接调用 `git ws1` 或 `git wm1`，降低操作范围。
- 大型变基前可记下 `git reflog` 或打临时 tag，失败时可 `git reset --hard <ref>` 回滚。`git rebase --abort` 也是常用兜底。
- 对于临时修改，优先使用 `git stash push` 保存；`git wmsa` 不会自动 stash，未提交改动会导致命令提前退出而非被覆盖。

按照上述流程准备与排查，可显著降低 `git wmsa` 在多 worktree 协同步一时的风险，确保主分支与各工作区保持一致。
