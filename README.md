# Claude Code Team Skills

基于 Claude Code Agent Team 能力的团队管理技能包。通过 5 个 slash command 实现团队的创建、保存、加载、查看和删除。

## 安装

```bash
npx skills add https://github.com/killvxk/TeamSkills
```

安装后会在 `~/.claude/skills/` 下创建 `team-init`、`team-save`、`team-load`、`team-list`、`team-delete` 五个目录。

## 命令一览

| 命令 | 说明 | 示例 |
|------|------|------|
| `/team-init` | 交互式创建团队 | `/team-init my-project` |
| `/team-save` | 保存当前团队为快照 | `/team-save my-team v2` |
| `/team-load` | 从配置加载团队 | `/team-load my-project` |
| `/team-list` | 查看已保存的配置 | `/team-list` |
| `/team-delete` | 删除已保存的配置 | `/team-delete my-project` |

## 支持的团队类型

| 类型 | Lead 角色 | 核心成员 | 适用场景 |
|------|----------|---------|---------|
| 软件开发 | PM | architect, developer, tester | 项目开发、功能迭代 |
| 软件测试 | 测试经理 | test-architect, functional-tester, automation-tester | 系统测试、质量保障 |
| 逆向工程 | 逆向负责人 | static-analyst, dynamic-analyst | 二进制分析、协议逆向 |
| 调试/Bug修复 | 调试负责人 | root-cause-analyst, fix-engineer | 故障排查、性能定位 |
| 安全研究 | 安全负责人 | vuln-hunter, security-auditor | 漏洞挖掘、安全评估 |
| CTF 比赛 | 队长 | web, pwn, reverse, crypto | CTF 竞赛 |
| 运维 | 运维经理 | sys-engineer, monitor-engineer | 部署运维、基础设施 |

## 工作流

```
/team-init ──→ 交互问答 ──→ 创建团队 ──→ 自动保存 template
                                │
                                ▼
                          使用过程中调整
                        (增删成员、改 prompt)
                                │
                                ▼
/team-save ──→ 读取运行状态 ──→ 保存 snapshot
                                │
                                ▼
/team-load ──→ 读取配置文件 ──→ 直接拉起团队（跳过问答）
```

## 配置格式

团队配置保存在项目目录的 `.team-profiles/` 下，支持两种格式：

### template — 由 `/team-init` 生成

存储角色代号，加载时从角色定义文件重新构建 prompt。文件小，角色定义随 skill 更新自动改进。

```yaml
format: template
team_type: "dev"
team_type_name: "软件开发"
description: "电商平台后端开发"
tech_stack: "Java, Spring Boot, PostgreSQL"
work_dir: "/projects/my-shop"

roles:
  - role: "pm"
    count: 1
    is_lead: true
  - role: "architect"
    count: 1
  - role: "developer"
    count: 2
  - role: "tester"
    count: 1
```

### snapshot — 由 `/team-save` 生成

存储每个成员的完整 prompt + 任务进度，自包含，可跨机器使用。

```yaml
format: snapshot
name: "my-shop"
description: "电商平台后端开发"
team_type: "dev"
team_type_name: "软件开发"

members:
  - name: "architect"
    agent_type: "general-purpose"
    model: "claude-opus-4-6"
    mode: "bypassPermissions"
    cwd: "/projects/my-shop"
    prompt: |
      你是「my-shop」项目的架构师。
      ...

tasks:
  - original_id: "1"
    subject: "完成需求分析"
    status: "completed"
    owner: "analyst"
    blocked_by: []
```

### 格式对比

| | template | snapshot |
|---|---|---|
| 来源 | `/team-init` 自动生成 | `/team-save` 手动保存 |
| 存储内容 | 角色代号 + 项目参数 | 完整 prompt + 任务进度 |
| 自包含 | 否，依赖角色定义文件 | 是 |
| 任务进度 | 不保存 | 保存所有任务状态和依赖 |
| mode 支持 | 固定 bypassPermissions | 保留实际 mode |
| 加载行为 | 读取角色定义重新构建 prompt | 直接使用保存的 prompt |

## 典型场景

### 首次创建团队

```
/team-init my-webapp
→ 选择「软件开发」→ 输入描述 → 选择技术栈 → 选择角色 → 确认
→ 自动保存到 .team-profiles/my-webapp.yaml (template)
```

### 调教后保存快照

```
/team-save my-webapp my-webapp-v2
→ 保存成员配置 + 任务进度到 .team-profiles/my-webapp-v2.yaml (snapshot)
```

### 下次直接加载

```
/team-load my-webapp-v2
→ 展示摘要 → 确认 → 团队拉起，恢复任务列表
```

### 同一配置用于不同项目

```
/team-load my-webapp-v2
→ 选择「修改名称和目录」→ 输入新名称和路径
→ 使用相同配置，项目名和路径不同
```

## 目录结构

```
.claude/skills/
├── team-init/
│   ├── SKILL.md
│   └── references/
│       ├── dev/                    # 软件开发
│       │   ├── workflow.md
│       │   └── roles/
│       │       ├── pm.md
│       │       ├── architect.md
│       │       ├── developer.md
│       │       └── ...
│       ├── testing/                # 软件测试
│       ├── reverse/                # 逆向工程
│       ├── debug/                  # 调试/Bug修复
│       ├── security/               # 安全研究
│       ├── ctf/                    # CTF 比赛
│       └── ops/                    # 运维
├── team-save/
│   └── SKILL.md
├── team-load/
│   └── SKILL.md
├── team-list/
│   └── SKILL.md
└── team-delete/
    └── SKILL.md
```

## 注意事项

- `.team-profiles/` 建议加入 `.gitignore`（snapshot 可能包含项目路径）
- template 格式依赖角色定义文件，跨机器需确保 skill 已安装
- snapshot 格式自包含，可直接复制到其他机器
- Lead 角色由系统自动创建，不包含在保存的配置中
- 加载 snapshot 时，原 in_progress 任务会重置为 pending（新 agent 没有之前的上下文）
- 加载时检测到同名团队正在运行会显示警告
- 覆盖保存时旧文件自动备份为 `.yaml.bak`

## License

MIT
