<p align="center">
  <strong>Team Skills &mdash; Agent 工程团队全生命周期管理插件</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License"></a>
  <img src="https://img.shields.io/badge/version-0.3.1-brightgreen?style=flat" alt="Version">
  <img src="https://img.shields.io/badge/skills-7-orange?style=flat" alt="Skills">
  <img src="https://img.shields.io/badge/core_roles-51-blue?style=flat" alt="Core Roles">
  <img src="https://img.shields.io/badge/extension_roles-146-purple?style=flat" alt="Extension Roles">
</p>

---

基于 Claude Code Agent Team 能力的工程团队管理插件。通过 7 个 slash command 实现团队的全生命周期管理：创建、保存、加载、查看、监控和终止。内置 51 个核心角色 + 146 个扩展专业角色，覆盖 8 种团队类型和 12 个扩展领域。

## Quick Start

**Method 1: Claude Code Plugin (推荐)**
```
/install-plugin https://github.com/killvxk/TeamSkills
```

**Method 2: 手动克隆**
```bash
git clone https://github.com/killvxk/TeamSkills.git
```

> 所有文件路径均使用相对引用，任何安装方式均可正常工作。

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

共 51 个核心角色定义，每个角色均采用 5 板块结构（`<role>` `<rules>` `<deliverables>` `<collaboration>` `<metrics>`），Lead 角色额外包含团队管理板块。

### 扩展角色库（146 个）

除核心角色外，可通过 `/team-init` 的交互式流程按需添加扩展专业角色：

| 领域 | 角色数 | 示例 |
|------|--------|------|
| engineering | 22 | 前端、后端、AI、DevOps、安全、嵌入式 |
| design | 8 | UI、UX、品牌、视觉叙事 |
| marketing | 29 | 小红书、抖音、微信、B站、SEO |
| game-development | 19 | Unity、Unreal、Godot、Roblox |
| paid-media | 7 | PPC、社交广告、程序化采买 |
| product | 4 | Sprint排序、趋势研究、反馈分析 |
| project-management | 6 | 制片人、项目协调、实验追踪 |
| sales | 8 | 赢单策略、售前工程、Pipeline分析 |
| support | 8 | 数据分析、法务合规、财务、招聘 |
| spatial-computing | 6 | visionOS、WebXR、Metal |
| specialized | 21 | 编排、区块链安全、MCP、合规 |
| testing | 8 | 证据收集、无障碍、API测试 |

扩展角色使用 `ext-{department}-{role_code}` 命名规则，在 prompt 中标注为「扩展角色 — {department}」。

> 扩展角色库基于 [agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh) 转换而来，已适配 TeamSkill 5 板块结构。

## 核心特性

### .teams/ 暂存机制

`/team-init` 在创建团队前，将角色定义复制到 `.teams/{project_name}/roles/`，用户可在编辑器中审阅和修改，确认后再启动团队。

### 分层工作流注入

- **Lead 角色**: 注入完整 workflow.md（包含各阶段详细流程）
- **执行角色**: 仅注入阶段总览表格（节省 prompt 长度）
- **扩展角色**: 与执行角色相同结构，额外标注扩展来源领域

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
/team-init ──→ 交互问答（含扩展角色选择）──→ .teams/ 暂存 ──→ 用户审阅 ──→ 创建团队
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

## Skill Anatomy

每个 skill 遵循统一的目录结构：

```
skills/{skill-name}/
├── SKILL.md              # Skill 定义（YAML frontmatter + 执行流程）
├── references/           # 角色定义、工作流等参考资源（仅 team-init）
│   ├── role-catalog.md
│   ├── shared/
│   ├── {team-type}/
│   └── extensions/
└── scripts/              # 工具脚本（仅 team-init）
    └── lint-roles.sh
```

## 目录结构

```
.claude-plugin/
├── plugin.json                    # 插件清单
└── marketplace.json               # Marketplace 元数据
skills/
├── team-init/
│   ├── SKILL.md                   # 团队创建流程定义
│   ├── scripts/
│   │   └── lint-roles.sh          # 角色格式校验脚本
│   └── references/
│       ├── role-catalog.md        # 角色索引（含扩展角色概览）
│       ├── shared/
│       │   ├── handoff-protocol.md
│       │   └── role-template.md
│       ├── dev/                   # 软件开发 (8 角色)
│       ├── testing/               # 软件测试 (6 角色)
│       ├── reverse/               # 逆向工程 (6 角色)
│       ├── debug/                 # 调试/Bug修复 (6 角色)
│       ├── security/              # 安全研究 (6 角色)
│       ├── ctf/                   # CTF 比赛 (7 角色)
│       ├── ops/                   # 运维 (7 角色)
│       ├── discuss/               # 讨论/研讨 (5 角色)
│       └── extensions/            # 扩展角色库 (146 角色, 12 领域)
│           ├── extension-catalog.md
│           ├── engineering/       # 22 角色
│           ├── design/            # 8 角色
│           ├── marketing/         # 29 角色
│           └── ...                # 其余 9 个领域
├── team-save/   └── SKILL.md
├── team-load/   └── SKILL.md
├── team-list/   └── SKILL.md
├── team-delete/ └── SKILL.md
├── team-status/ └── SKILL.md
└── team-stop/   └── SKILL.md
```

## 注意事项

- `.team-profiles/` 和 `.teams/` 建议加入 `.gitignore`
- template 格式依赖角色定义文件，跨机器需确保插件已安装
- snapshot 格式自包含，可直接复制到其他机器
- 加载 snapshot 时，原 in_progress 任务会重置为 pending（新 agent 没有之前的上下文）
- 加载时检测到同名团队正在运行会显示警告
- 覆盖保存时旧文件自动备份为 `.yaml.bak`

## License

MIT
