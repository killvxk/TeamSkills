# Claude Code Team Skills

基于 Claude Code Agent Team 能力的团队管理技能包。通过 7 个 slash command 实现团队的全生命周期管理：创建、保存、加载、查看、监控和终止。内置 51 个专业角色定义，覆盖 8 种团队类型。

## 安装

### 方式一：克隆到项目（推荐）

```bash
git clone https://github.com/killvxk/TeamSkills .claude/skills-repo
cp -r .claude/skills-repo/.claude/skills/* .claude/skills/
```

### 方式二：全局安装

```bash
# 复制到全局 skills 目录
git clone https://github.com/killvxk/TeamSkills /tmp/TeamSkills
cp -r /tmp/TeamSkills/.claude/skills/* ~/.claude/skills/
```

> 所有文件路径均使用相对引用，项目级和全局安装均可正常工作。

## 命令一览

| 命令 | 说明 | 示例 |
|------|------|------|
| `/team-init` | 交互式创建团队 | `/team-init my-project` |
| `/team-save` | 保存当前团队为快照 | `/team-save my-team v2` |
| `/team-load` | 从配置加载团队 | `/team-load my-project` |
| `/team-list` | 查看已保存的配置 | `/team-list` |
| `/team-delete` | 删除已保存的配置 | `/team-delete my-project` |
| `/team-status` | 查看运行中的团队状态 | `/team-status my-project` |
| `/team-stop` | 终止运行中的团队 | `/team-stop my-project` |

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
| 讨论/研讨 | 主持人 | domain-expert, critic, synthesizer | 方案设计、技术选型、头脑风暴 |

共 51 个角色定义，每个角色均采用 5 板块结构（`<role>` `<rules>` `<deliverables>` `<collaboration>` `<metrics>`），Lead 角色额外包含团队管理板块。

## 核心特性

### .teams/ 暂存机制

`/team-init` 在创建团队前，将角色定义复制到 `.teams/{project_name}/roles/`，用户可在编辑器中审阅和修改，确认后再启动团队。

### 分层工作流注入

- **Lead 角色**: 注入完整 workflow.md（包含各阶段详细流程）
- **执行角色**: 仅注入阶段总览表格（节省 prompt 长度）

### 配置格式

团队配置保存在 `.team-profiles/` 下，支持两种格式：

| | template | snapshot |
|---|---|---|
| 来源 | `/team-init` 自动生成 | `/team-save` 手动保存 |
| 存储内容 | 角色代号 + 项目参数 | 完整 prompt + 任务进度 |
| 自包含 | 否，依赖角色定义文件 | 是 |
| 加载行为 | 读取角色定义重新构建 prompt | 直接使用保存的 prompt |

Snapshot 加载时支持「仅结构加载」模式：复用团队组成但使用最新角色定义，适合角色更新后重建团队。

### 跨角色交接协议

所有角色共享统一的 `handoff-protocol.md` 交接规范，确保团队成员间的信息传递格式一致。

## 工作流

```
/team-init ──→ 交互问答 ──→ .teams/ 暂存 ──→ 用户审阅 ──→ 创建团队
                                                              │
                                                              ▼
/team-status ←── 查看运行状态 ←── 使用过程中调整（增删成员、改 prompt）
                                                              │
                                                              ▼
/team-save ──→ 读取运行状态 ──→ 保存 snapshot ──→ /team-load 复用
                                                              │
                                                              ▼
/team-stop ──→ 确认终止 ──→ 清理资源
```

## 目录结构

```
.claude/skills/
├── team-init/
│   ├── SKILL.md                     # 团队创建流程定义
│   ├── scripts/
│   │   └── lint-roles.sh            # 角色格式校验脚本
│   └── references/
│       ├── role-catalog.md          # 角色索引
│       ├── shared/
│       │   ├── handoff-protocol.md  # 跨角色交接协议
│       │   └── role-template.md     # 角色定义模板
│       ├── dev/                     # 软件开发 (8 角色)
│       │   ├── workflow.md
│       │   └── roles/
│       ├── testing/                 # 软件测试 (6 角色)
│       ├── reverse/                 # 逆向工程 (6 角色)
│       ├── debug/                   # 调试/Bug修复 (6 角色)
│       ├── security/                # 安全研究 (6 角色)
│       ├── ctf/                     # CTF 比赛 (7 角色)
│       ├── ops/                     # 运维 (7 角色)
│       └── discuss/                 # 讨论/研讨 (5 角色)
├── team-save/   └── SKILL.md
├── team-load/   └── SKILL.md
├── team-list/   └── SKILL.md
├── team-delete/ └── SKILL.md
├── team-status/ └── SKILL.md       # 运行时团队状态查看
└── team-stop/   └── SKILL.md       # 团队终止与资源清理
```

## 注意事项

- `.team-profiles/` 和 `.teams/` 建议加入 `.gitignore`
- template 格式依赖角色定义文件，跨机器需确保 skill 已安装
- snapshot 格式自包含，可直接复制到其他机器
- 加载 snapshot 时，原 in_progress 任务会重置为 pending（新 agent 没有之前的上下文）
- 加载时检测到同名团队正在运行会显示警告
- 覆盖保存时旧文件自动备份为 `.yaml.bak`

## License

MIT
