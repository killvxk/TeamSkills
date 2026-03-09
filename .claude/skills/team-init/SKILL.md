---
name: team-init
description: |
  This skill should be used when the user asks to "初始化团队", "创建开发团队",
  "team init", "组建团队", "启动项目团队". 通过交互式问答收集项目信息，
  创建包含专业角色的 Agent 工程团队。支持 8 种团队类型：软件开发、软件测试、
  逆向工程、调试/Bug修复、安全研究、CTF比赛、软件与服务器运维、讨论/研讨。
argument-hint: "[项目名称]"
disable-model-invocation: true
version: 0.1.0
---

# 工程团队初始化

通过交互式问答，收集项目信息并创建由 Lead 领导的 Agent 工程团队。

## 支持的团队类型

| # | 类型 | 领导角色 | 目录 | 适用场景 |
|---|------|---------|------|---------|
| 1 | 软件开发 | PM | dev | 全新项目开发、功能迭代 |
| 2 | 软件测试 | 测试经理 | testing | 系统测试、质量保障 |
| 3 | 逆向工程 | 逆向负责人 | reverse | 二进制分析、协议逆向、恶意软件分析 |
| 4 | 调试/Bug修复 | 调试负责人 | debug | 故障排查、性能问题定位 |
| 5 | 安全研究 | 安全负责人 | security | 漏洞挖掘、安全评估(需合法授权) |
| 6 | CTF 比赛 | 队长 | ctf | CTF 竞赛、安全挑战 |
| 7 | 运维 | 运维经理 | ops | 部署运维、基础设施管理 |
| 8 | 讨论/研讨 | 主持人 | discuss | 方案设计、技术选型、需求研讨、头脑风暴 |

各类型的详细角色列表见 `references/role-catalog.md`。

## 交互式问答流程

按顺序使用 AskUserQuestion 工具向用户提问。

### 问题 0: 团队类型

```
AskUserQuestion:
  question: "请选择要创建的团队类型"
  header: "团队类型"
  options:
    - label: "软件开发"
      description: "全新项目开发、功能迭代"
    - label: "软件测试"
      description: "系统测试、质量保障"
    - label: "逆向工程"
      description: "二进制分析、协议逆向"
    - label: "调试/Bug修复"
      description: "故障排查、性能定位"
    - label: "安全研究"
      description: "漏洞挖掘、安全评估(需合法授权)"
    - label: "CTF 比赛"
      description: "CTF 竞赛、安全挑战"
    - label: "运维"
      description: "部署运维、基础设施管理"
    - label: "讨论/研讨"
      description: "方案设计、技术选型、需求研讨、头脑风暴"
  multiSelect: false
```

记录用户选择的 `team_type`，映射到对应目录名：
- 软件开发 → dev
- 软件测试 → testing
- 逆向工程 → reverse
- 调试/Bug修复 → debug
- 安全研究 → security
- CTF 比赛 → ctf
- 运维 → ops
- 讨论/研讨 → discuss

### 问题 1: 项目名称

如果 `$ARGUMENTS` 非空，使用其作为项目名称，跳过此问题。

```
AskUserQuestion:
  question: "请输入项目名称（英文，用作 team name，如 my-webapp）"
  header: "项目名称"
  options:
    - label: "my-project"
      description: "使用默认名称"
    - label: "输入自定义名称"
      description: "在「其他」中输入"
  multiSelect: false
```

### 问题 2: 项目描述

```
AskUserQuestion:
  question: "{根据 team_type 调整措辞}"
  header: "项目描述"
  options: {根据 team_type 提供 2-4 个典型场景选项}
  multiSelect: false
```

措辞映射：
- dev: "请简要描述项目目标和范围"
- testing: "请描述被测系统和测试目标"
- reverse: "请描述逆向目标和分析目的"
- debug: "请描述需要调试的问题和症状"
- security: "请描述安全研究的目标和范围"
- ctf: "请描述比赛名称和赛制"
- ops: "请描述运维目标和基础设施概况"
- discuss: "请描述讨论议题和期望产出"

### 问题 3: 技术栈/目标平台

```
AskUserQuestion:
  question: "{根据 team_type 调整措辞}"
  header: "技术栈"
  options: {根据 team_type 提供 2-4 个典型选项}
  multiSelect: true
```

措辞映射：
- dev: "项目使用什么技术栈？"
- testing: "被测系统的技术栈？"
- reverse: "目标平台和架构？（x86/ARM/MIPS, Windows/Linux/Android）"
- debug: "问题所在的技术栈和环境？"
- security: "研究目标的技术栈和平台？"
- ctf: "比赛偏好方向和工具？"
- ops: "基础设施技术栈？（Linux/K8s/AWS/Docker）"
- discuss: "讨论涉及哪些领域？（用于配置专家角色的专业背景）"

### 问题 4: 角色选择

展示当前 team_type 的角色列表。Lead 角色自动包含，无需选择。

```
AskUserQuestion:
  question: "选择需要的角色（{lead_role} 默认包含）。多实例角色可在「其他」中用 'developer x2' 格式指定数量"
  header: "团队角色"
  multiSelect: true
  options:
    - label: "全部角色 (推荐)"
      description: "包含该类型所有角色各 1 个"
    - label: "核心团队"
      description: "{该类型的核心角色子集}"
    - label: "最小团队"
      description: "{lead + 1-2 个核心角色}"
    - label: "自定义"
      description: "在「其他」中指定角色和数量"
  multiSelect: false
```

核心团队映射：
- dev: pm + architect + developer + tester
- testing: test-manager + test-architect + functional-tester + automation-tester
- reverse: re-lead + static-analyst + dynamic-analyst
- debug: debug-lead + root-cause-analyst + fix-engineer
- security: security-lead + vuln-hunter + security-auditor
- ctf: captain + web + pwn + reverse
- ops: ops-manager + sys-engineer + monitor-engineer
- discuss: moderator + domain-expert + critic + synthesizer

最小团队映射：
- dev: pm + developer
- testing: test-manager + functional-tester
- reverse: re-lead + static-analyst
- debug: debug-lead + fix-engineer
- security: security-lead + vuln-hunter
- ctf: captain + web
- ops: ops-manager + sys-engineer
- discuss: moderator + domain-expert

### 问题 4.5: 讨论轮次（仅 discuss 类型触发）

```
AskUserQuestion:
  question: "每个议题的最大讨论轮次？"
  header: "讨论轮次"
  options:
    - label: "3 轮（默认）"
    - label: "5 轮"
    - label: "自定义"
  multiSelect: false
```

`max_rounds` 写入配置和 prompt 的 `<project_context>` 中。

### 问题 5: 工作目录

```
AskUserQuestion:
  question: "项目工作目录在哪里？"
  header: "工作目录"
  options:
    - label: "当前目录"
      description: "使用当前工作目录"
    - label: "指定路径"
      description: "在「其他」中输入绝对路径"
  multiSelect: false
```

### 确认步骤

输出汇总信息，然后确认：

```
团队配置汇总
--------------------
团队类型: {team_type_name}
项目名称: {project_name}
项目描述: {description}
技术栈:   {tech_stack}
工作目录: {work_dir}

团队成员:
  - {lead_role} x1 (Lead)
  - {role_name} x{count}
  ...

预计创建 {N} 个 Agent
--------------------
```

```
AskUserQuestion:
  question: "确认以上配置并创建团队？"
  header: "确认"
  options:
    - label: "确认创建"
      description: "开始创建团队"
    - label: "修改配置"
      description: "重新开始问答"
    - label: "取消"
      description: "放弃创建"
  multiSelect: false
```

## 团队创建流程

用户确认后，执行以下步骤。

### 步骤 1: 创建团队

```
TeamCreate:
  team_name: "{project_name}"
  description: "{team_type_name} - {description}"
```

### 步骤 2: 读取角色定义和工作流

角色定义路径: `~/.claude/skills/team-init/references/{type_dir}/roles/{role_code}.md`
工作流路径: `~/.claude/skills/team-init/references/{type_dir}/workflow.md`

> **注意**: 以上路径以 skill 实际安装目录为准。使用 Read 工具时需要确认 skill 所在的实际路径。

对每个选中的角色，使用 Read 工具读取其角色定义文件。
同时读取该类型的 workflow.md。

### 步骤 3: 构建角色 Prompt

为每个成员组合 prompt：

```
你是「{project_name}」项目的{role_name}。

<project_context>
项目名称: {project_name}
团队类型: {team_type_name}
项目描述: {description}
技术栈: {tech_stack}
工作目录: {work_dir}
</project_context>

<team_members>
{列出所有成员的名称和角色}
</team_members>

<workflow>
{workflow.md 的内容}
</workflow>

<your_role>
{对应角色 .md 文件的完整内容}
</your_role>
```

### 步骤 4: 创建初始任务

使用 TaskCreate 根据 workflow.md 的阶段创建任务骨架。
设置阶段间的 blockedBy 依赖关系。
将第一个任务分配给 Lead 角色。

### 步骤 5: 派生团队成员

**Lead 角色必须第一个创建。**

```
Agent:
  name: "{member_name}"
  subagent_type: "general-purpose"
  team_name: "{project_name}"
  prompt: "{步骤 3 构建的 prompt}"
  mode: "bypassPermissions"
  description: "Team member: {role_name}"
```

命名规则：
- 单实例角色: 直接使用代号 (pm, architect, captain 等)
- 多实例角色: 代号-序号 (developer-1, web-2 等)

创建顺序：先创建 Lead，再并行创建其他角色。

### 步骤 6: 保存团队配置到项目目录

将团队配置保存到项目工作目录下的 `.team-profiles/{project_name}.yaml`，以便后续通过 `/team-load` 复用。

使用 Write 工具创建文件：

```yaml
# 团队配置 - 由 /team-init 自动生成
# 使用 /team-load {project_name} 可直接加载此配置创建团队

format: template
team_type: "{type_dir}"           # dev/testing/reverse/debug/security/ctf/ops/discuss
team_type_name: "{team_type_name}" # 中文名称
description: "{description}"
tech_stack: "{tech_stack}"
work_dir: "{work_dir}"

roles:
  # Lead 角色（自动包含）
  - role: "{lead_role_code}"
    count: 1
    is_lead: true
  # 其他角色
  - role: "{role_code}"
    count: {N}
  # ... 列出所有选中的角色及数量
```

保存后输出提示：
```
团队配置已保存到: {work_dir}/.team-profiles/{project_name}.yaml
后续可使用 /team-load {project_name} 直接加载此团队配置。
```

### 步骤 7: 通知 Lead 启动

```
SendMessage:
  type: "message"
  recipient: "{lead_name}"
  content: |
    团队已创建完成。
    - 项目: {project_name}
    - 描述: {description}
    - 技术栈: {tech_stack}
    - 工作目录: {work_dir}
    - 团队成员: {member_list}

    请开始第一阶段工作。
    团队配置: ~/.claude/teams/{project_name}/config.json
    工作流: ~/.claude/skills/team-init/references/{type_dir}/workflow.md
    角色定义: ~/.claude/skills/team-init/references/{type_dir}/roles/
  summary: "团队已创建，启动项目"
```

## 参考资源

- **`references/role-catalog.md`** - 各团队类型的完整角色列表
- **`references/{type_dir}/roles/{role}.md`** - 各角色详细定义
- **`references/{type_dir}/workflow.md`** - 各团队类型的工作流定义
