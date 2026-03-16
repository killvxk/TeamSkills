---
name: team-stop
description: |
  This skill should be used when the user asks to "停止团队", "team stop",
  "终止团队", "关闭团队", "解散团队", "stop team", "terminate team",
  "shutdown team", "disband team". 主动终止运行中的团队，
  向所有成员发送关闭请求并清理团队资源。
version: 0.3.0
---

# 团队终止

主动终止运行中的团队，向所有成员发送关闭请求。

## 与 Lead 内部终止的区别

| | Lead 角色内部终止 | /team-stop 外部终止 |
|---|---|---|
| 触发方 | Lead 角色在项目完成后自行发起 | 用户从外部主动发起 |
| 流程 | 逐个 shutdown_request → 等待确认 → 自我关闭 | 用户确认后批量终止 |
| 适用场景 | 正常项目收尾 | 强制终止、放弃项目、团队卡死 |

## 流程

### 步骤 1: 确定要终止的团队

如果 `$ARGUMENTS` 非空，直接使用作为团队名称。

否则，扫描 `~/.claude/teams/` 目录列出运行中的团队：

```bash
ls ~/.claude/teams/ 2>/dev/null
```

如果目录不存在或为空：

```
当前没有运行中的团队。
```

结束。

如果有多个团队：

```
AskUserQuestion:
  question: "选择要终止的团队"
  header: "终止团队"
  options:
    - label: "{team_name_1}"
      description: "{description_1}"
    - label: "{team_name_2}"
      description: "{description_2}"
    - label: "全部终止"
      description: "终止所有运行中的团队"
  multiSelect: false
```

### 步骤 2: 展示团队信息并确认

读取 `~/.claude/teams/{team_name}/config.json`，展示摘要：

```
即将终止团队: {team_name}
--------------------
描述: {description}
成员: {N} 个
```

使用 TaskList 获取任务状态，展示未完成任务警告（如有）：

```
⚠ 未完成的任务:
  ⚡ #{id} {subject} (进行中, 负责人: {owner})
  ○ #{id} {subject} (待处理)
  共 {count} 个任务未完成，终止后将丢失进度。
--------------------
```

提供保存选项：

```
AskUserQuestion:
  question: "确认终止团队？未完成的工作将丢失。"
  header: "确认终止"
  options:
    - label: "先保存再终止"
      description: "保存当前状态到 .team-profiles/ 后再终止"
    - label: "直接终止"
      description: "不保存，直接终止团队"
    - label: "取消"
      description: "放弃终止"
  multiSelect: false
```

### 步骤 3: 保存（如用户选择"先保存再终止"）

执行以下保存流程（保存名称默认为 `{team_name}`），完成后继续步骤 4：

1. 读取 `~/.claude/teams/{team_name}/config.json`，提取成员列表（排除 `agentType: "team-lead"`）
2. 使用 TaskList / TaskGet 采集当前任务进度
3. 确保目录存在：`mkdir -p "{当前工作目录}/.team-profiles"`
4. 如果 `.team-profiles/{team_name}.yaml` 已存在，备份为 `.yaml.bak`
5. 使用 Write 写入快照 YAML（`format: snapshot`，包含成员 prompt 和任务进度，格式参考 `/team-save` skill）
6. 输出保存确认：`团队快照已保存到: .team-profiles/{team_name}.yaml`

### 步骤 4: 向所有成员发送关闭请求

读取 config.json 获取所有成员（排除 `agentType: "team-lead"`），逐个发送关闭请求：

```
SendMessage:
  type: "message"
  recipient: "{member_name}"
  content: |
    收到团队终止指令。请立即停止当前工作并确认关闭。
    - 如有未保存的工作，请先保存到工作目录
    - 回复确认后将被关闭
  summary: "团队终止，请确认关闭"
```

**并行发送**：所有 SendMessage 可以在同一轮次内并行发送，无需逐个等待。

**错误处理**：如果某成员无法接收消息（已断开或无响应），记录警告并继续终止流程，不因个别成员无法通知而阻塞整个终止过程。

### 步骤 5: 清理团队资源

使用 TeamDelete 工具删除团队：

```
TeamDelete:
  team_name: "{team_name}"
```

如果 TeamDelete 工具不可用，使用 Bash 清理：

```bash
rm -rf "$HOME/.claude/teams/{team_name}"
```

### 步骤 6: 输出结果

```
团队已终止: {team_name}
  - {N} 个成员已关闭
  - 团队资源已清理
```

如果执行了保存：
```
  - 快照已保存到: .team-profiles/{team_name}.yaml
  - 可使用 /team-load {team_name} 恢复团队
```

如果选择了"全部终止"，对每个团队重复步骤 2-6，最后输出汇总：

```
已终止 {N} 个团队:
  - {team_name_1} ({member_count_1} 个成员)
  - {team_name_2} ({member_count_2} 个成员)
所有团队资源已清理。
```

## 注意事项

- 终止操作不可逆，提前保存是唯一的恢复手段
- 即使成员未回复确认，TeamDelete 仍会强制清理资源
- `.team-profiles/` 下的配置文件不受影响（那是磁盘上的持久化配置，不是运行时状态）
- 如果团队已经不存在（config.json 不在），直接报告 "团队 {name} 不存在或已终止"
