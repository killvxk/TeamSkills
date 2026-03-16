---
name: team-status
description: |
  This skill should be used when the user asks to "查看团队状态", "team status",
  "check team progress", "who is running", "团队运行情况", "团队进度",
  "谁在运行", "active teams". 查询当前运行中的团队的实时状态，
  包括成员列表、任务进度和活跃情况。与 /team-list（查看磁盘配置）互补。
version: 0.4.0
---

# 运行中团队状态查询

查询当前运行中的团队实时状态，展示成员、任务进度和活跃情况。

## 与 /team-list 的区别

| | /team-list | /team-status |
|---|---|---|
| 数据来源 | `.team-profiles/*.yaml`（磁盘） | `~/.claude/teams/`（运行时） |
| 内容 | 已保存的配置模板/快照 | 当前活跃团队的实时状态 |
| 用途 | 查看可加载的配置 | 查看正在运行的团队 |

## 流程

### 步骤 1: 扫描运行中的团队

使用 Bash 工具扫描 `~/.claude/teams/` 目录：

```bash
ls ~/.claude/teams/ 2>/dev/null
```

如果目录不存在或为空：

```
当前没有运行中的团队。

- /team-init  创建新团队
- /team-load  从已保存的配置加载团队
```

结束。

### 步骤 2: 确定查询目标

如果 `$ARGUMENTS` 非空，直接使用作为团队名称。

如果有多个运行中的团队且未指定名称：

```
AskUserQuestion:
  question: "查看哪个团队的状态？"
  header: "选择团队"
  options:
    - label: "{team_name_1}"
      description: "查看此团队状态"
    - label: "{team_name_2}"
      description: "查看此团队状态"
    - label: "全部"
      description: "查看所有运行中的团队"
  multiSelect: false
```

如果只有一个团队，直接查询该团队。

### 步骤 3: 读取团队配置

使用 Read 工具读取 `~/.claude/teams/{team_name}/config.json`，提取：

- **团队名称** (`name`)
- **团队描述** (`description`)
- **成员列表** (`members[]`)：每个成员的 name、agentType、color
- **创建时间**（`createdAt` 字段，如果存在；不存在则省略）

### 步骤 4: 获取任务状态

使用 TaskList 工具获取当前任务列表。

对每个任务统计：
- `completed`: 已完成数量
- `in_progress`: 进行中数量
- `pending`: 待处理数量

对关键任务（in_progress 和 blocked）使用 TaskGet 获取详细信息：
- 任务标题、负责人、阻塞依赖

### 步骤 5: 输出状态报告

```
团队状态: {team_name}
========================================
描述: {description}
成员: {N} 个活跃

成员列表:
  {color} {member_name}  ({agentType})
  {color} {member_name}  ({agentType})
  ...
  （排除 team-lead 类型成员）

任务进度: {total} 个任务
  ✓ 已完成: {completed}
  ⚡ 进行中: {in_progress}
  ○ 待处理: {pending}

进行中的任务:
  #{id} {subject}  → {owner}
  #{id} {subject}  → {owner}

阻塞项:
  #{id} {subject}  ← 等待 #{blocked_by_id}
  （如无阻塞项则显示 "无阻塞项"）

完成进度: [{progress_bar}] {percent}%
========================================

操作提示:
- /team-save {team_name}  保存当前状态
- /team-stop {team_name}  终止团队
```

进度条生成规则：
- 总宽度 20 字符
- 已完成用 `█` 填充，未完成用 `░` 填充
- 百分比 = completed / total × 100

### 步骤 6: 多团队汇总（仅当选择"全部"时）

对每个团队重复步骤 3-5，最后输出汇总：

```
运行中的团队汇总
========================================
  {team_name_1}  {N}人  [{bar}] {percent}%
  {team_name_2}  {N}人  [{bar}] {percent}%
========================================
共 {total_teams} 个团队运行中。
```

## 注意事项

- 只读操作，不修改任何文件或状态
- `~/.claude/teams/` 下的子目录名即为团队名称
- config.json 中 `agentType: "team-lead"` 的成员不计入成员列表展示
- 如果 config.json 解析失败，输出 `⚠ {team_name} 配置异常` 并跳过
- TaskList 可能返回空（新创建的团队尚无任务），此时显示 "尚无任务"
