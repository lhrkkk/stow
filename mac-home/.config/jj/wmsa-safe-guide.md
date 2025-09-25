# jj `wmsa` 安全使用说明

`jj wmsa` 是一个组合指令，用来在多工作区（one/two/three）之间快速完成“合并 + 同步 + 切换到 default”的日常流程。为了安全使用，需要了解它在什么前提下工作、会在哪些环节失败，以及出现问题时如何恢复。

## 指令链路概览

- `jj wmsa`
  - 打印 `[wmsa] jj: wma + wsa: 合并和同步所有分支`。
  - 执行 `jj wma`（依次调用 `jj wm1` / `jj wm2` / `jj wm3`）。
  - 在 `jj wma` 成功后执行 `jj wsa`（依次调用 `jj ws1` / `jj ws2` / `jj ws3`）。
  - 最后运行 `jj n default`（`jj new default`），静默地把默认工作区重新挂到最新 `default` 节点。
- `jj wm{1,2,3}`
  - 判定对应 bookmark（`one@`/`two@`/`three@`）是否存在。
  - 执行 `jj rb -b <name>@- -d default` 把上一次同步结果 rebase 到最新的 `default`。
  - 成功后执行 `jj bs default -r <name>@-`，把 `default` bookmark 快进到工作区的最新节点。
- `jj ws{1,2,3}`
  - 判定 `<name>@` 是否存在；不存在直接 `skip`。
  - 执行 `jj rb -b <name>@ -d default`，把工作区当前提交 rebase 到 `default`。
  - 打印最新提交的 `commit_id.short()` 与首行描述，便于确认落点。
- `jj wsa`
  - 对 three 个工作区重复 `jj rb -b <name>@ -d default`，并把输出规整成 `[wsa] -> [wsN] ...` 的形式。

这些 alias 定义可在 `mac-home/.config/jj/config.toml` 的 473–488 行查看。

## 运行前检查清单

1. **确认工作区存在且名称正确**：`jj workspace list` 应至少包含 `default`、`one`、`two`、`three`。缺少时使用 `jj wa1|wa2|wa3` 重新创建。
2. **确认 bookmark 存在**：`jj log -r one@ --no-pager -n 1`（two/three 同理）应返回正常记录。若提示 `Revision "one@" didn't resolve`，说明工作区从未同步过，需要先手动 `jj new` 或 `jj ws1` 一次。
3. **检查冲突与未完成操作**：对三个工作区分别执行 `jj wo1 jj status`（two/three 同理），确保没有冲突 (`conflict`) 或尚未解决的合并。
4. **默认工作区保持可切换**：在 `default` 工作区执行 `jj status`，至少确保没有正在进行的合并冲突或脏状态；否则 `jj n default` 可能失败。

## 常见失败情形与提示

| 环节 | 触发条件 | 典型提示 | 处理建议 |
| ---- | -------- | -------- | -------- |
| 启动 | 在非 JJ 仓库目录执行 | `error: No jj repo found` | 切换到正确仓库根目录（`jj workspace root`）。|
| wmN | `.jj/workspace-one` 目录缺失 | `[wm1] skip: head missing` | 通过 `jj wa1` 重新添加工作区，或检查 `.jj/workspace-one` 是否被移走。|
| wmN | `one@` 没有任何历史（从未同步） | `[wm1] skip: head missing` | 先运行 `jj ws1` 生成首个同步节点，或手动在 workspace-one commit 后再执行。|
| wmN | `jj rb -b one@- -d default` 产生冲突 | `[wm1] fail: Rebase aborted: ...` | `jj wo1` 进入 workspace-one，运行 `jj rb -b one@- -d default`，按提示解决冲突并 `jj resolve --list`/`jj commit`，再重试 `jj wmsa`。|
| wmN | `jj bs default -r one@-` 被拒绝 | `[wm1] fail: ... bookmark ... already matches target ...` 或远端保护提示 | 确认 `default` 是否被其他 bookmark/远端锁定；必要时改用 `jj bs default -r one@- --allow-backwards`（谨慎）。|
| wsa / wsN | `jj rb -b one@ -d default` 冲突 | `[ws1] fail: Rebase aborted: ...` 或直接停在 `[wsa] -> [ws1] fail: ...` | 到 workspace-one 内解决冲突（`jj ws1` 已打印命令，照做即可），完成后再运行 `jj wmsa`。|
| wsa | 工作区缺失 | `[wsa] -> [ws1] skip: head missing` | 行为等同 `wsN` 缺失，属于提醒，不是错误；确认是否预期跳过。|
| 尾部 | `jj n default` 失败 | 报错提示默认工作区仍有冲突或脏状态（如 `Working copy contains conflicts`） | 在默认工作区处理冲突或清理未完成修改，再手动 `jj n default`。|

> 说明：如果多个工作区已经位于同一提交，`jj rb -b <rev> -d default` 会打印 `Nothing changed.` 并返回 0；`jj wmsa` 会继续执行，不会因此报错。

## 故障排查流程

1. **记录哪一步失败**：`jj wmsa` 会把第一个失败步骤的首行错误信息打印出来（例如 `[wm2] fail: ...` 或 `[wsa] -> [ws3] fail: ...`）。
2. **单独重放子命令**：针对失败步骤运行对应 alias（如 `jj wm2`），便于查看完整输出；若仍不清楚，可展开为底层命令 `jj rb ...`、`jj bs ...`。
3. **在工作区内处理冲突**：使用 `jj wo2` 进入指定工作区，`jj status` 查看冲突文件，按 JJ 的冲突解决流程处理后 `jj resolve --mark-resolved`，最后 `jj status` 确认干净。
4. **重新验证**：冲突解决后先运行 `jj wsN` / `jj wmN` 确认通过，再执行一次 `jj wmsa`。
5. **保持操作单线程**：避免同时在多个终端对同一仓库运行 `jj wmsa` 或其他会改写 bookmark 的命令，防止出现“bookmark 已被其他操作更新”的竞态。

## 安全使用建议

- 在正式执行 `jj wmsa` 前，先运行 `jj wsl` 查看三个工作区的目录与头部状态是否良好。
- 如果只是想同步某一个工作区，可以单独调用 `jj ws1` / `jj wm1`，避免一次性操作全部节点。
- 在复杂 rebase 前，考虑使用 `jj op log --no-pager` 记录当前操作 ID，必要时可以 `jj op restore <op-id>` 回滚。
- 定期清理孤立空提交：`jj clean` 已在配置中提供，适度使用可减少噪音。

按上述步骤准备和排查，可大幅降低 `jj wmsa` 在批量同步时的风险，确保多工作区协同保持稳定可靠。
