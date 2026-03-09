# 讨论型团队（discuss）设计文档

**日期**: 2026-03-10
**状态**: 已确认

## 背景与目标

现有 7 种团队类型均为"执行型"——Lead 分配任务、成员独立执行、阶段门禁审核。缺少"讨论型"团队支持多角色相互讨论、提出意见、达成共识的场景。

目标：在 team-init 中新增第 8 种团队类型"讨论/研讨"（discuss），支持方案设计、技术选型、需求研讨、头脑风暴等场景。

## 设计决策

### 集成方式
- 作为 team-init 的第 8 种类型，而非独立 skill
- 理由：复用创建流程、自动兼容 save/load/list/delete

### 协作模式：消息广播 + 共享文档（方案 C）
- 每轮：主持人广播议题 → 专家提交观点 → 主持人广播所有观点 → 交叉回应 → 汇总
- 讨论文档在工作目录自动积累

### 共识机制：多轮收敛 + 超时裁定
- 先尝试多轮收敛，每轮缩小讨论范围至剩余分歧点
- 达到 max_rounds 仍未收敛时，主持人综合各方论据裁定
- max_rounds 由用户创建时指定，默认 3 轮

## team-init 集成点

### 团队类型表新增

| # | 类型 | 领导角色 | 目录 | 适用场景 |
|---|------|---------|------|---------|
| 8 | 讨论/研讨 | 主持人 | discuss | 方案设计、技术选型、需求研讨、头脑风暴 |

### 映射新增
- 问题 0 选项：`"讨论/研讨"` → `discuss`
- Lead 角色：`moderator`
- 核心团队：`moderator + domain-expert + critic + synthesizer`
- 最小团队：`moderator + domain-expert`
- 问题 2 措辞："请描述讨论议题和期望产出"
- 问题 3 措辞："讨论涉及哪些领域？（用于配置专家角色的专业背景）"

### 新增问题 4.5（仅 discuss 类型触发）
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

## 角色定义

| 角色 | 代号 | 可多实例 | 职责 |
|------|------|----------|------|
| 主持人 | moderator | 否 | 议程管控、广播观点、汇总分歧、推动收敛、裁定 |
| 领域专家 | domain-expert | 是 | 从专业角度分析议题、提出方案、回应质疑 |
| 批判者 | critic | 否 | 专职提出反对意见、风险质疑、挑战假设 |
| 综合提炼者 | synthesizer | 否 | 整合各方观点、提炼共识、生成产出文档 |
| 记录员 | recorder | 否 | 实时维护讨论文档、记录关键论点和决策 |

### 角色设计要点

**moderator（主持人/Lead）**：
- 拥有团队管理能力（招募/解散）
- 核心流程：议题分解 → 征集 → 广播 → 交叉回应 → 汇总 → 收敛判断
- 达到 max_rounds 时裁定

**domain-expert（领域专家）**：
- prompt 中注入用户提供的领域信息
- 支持多实例，每个专注不同领域
- 观点格式：立场 + 论据 + 风险评估
- 支持动态专业背景（用户自定义时由主持人构建）

**critic（批判者，可选）**：
- 对每个方案必须提出至少一个反对理由或风险
- 禁止无条件赞同

**synthesizer（综合提炼者）**：
- 每轮提炼：共识点、分歧点、新发现
- 讨论结束时生成最终产出文档

**recorder（记录员，可选）**：
- 维护共享讨论文档
- 最小团队中由 moderator 兼任

## 讨论工作流

```
Phase 0: 议题设定
  [议题循环] 对每个议题:
    Phase 1: 观点征集
    Phase 2: 交叉讨论
    Phase 3: 汇总评估
      收敛? → Phase 4
      未收敛且未达 max_rounds? → 回到 Phase 1（仅讨论分歧点）
      达到 max_rounds? → Phase 4（主持人裁定）
Phase 5: 产出整合
```

### Phase 0: 议题设定
- 激活：moderator
- 分析项目描述，拆解为议题列表
- 每个议题含：标题、背景、期望产出类型
- TaskCreate 为每个议题创建任务

### Phase 1: 观点征集（每轮）
- 激活：moderator, domain-expert, critic
- 主持人广播议题/上轮分歧焦点
- 专家提交观点（立场+论据+风险）
- critic 质疑已提交观点

### Phase 2: 交叉讨论（每轮）
- 激活：全体
- 主持人广播所有原始观点
- 成员回应（赞同/反对/补充），每人限 1-2 条
- recorder 更新讨论文档

### Phase 3: 汇总评估（每轮）
- 激活：moderator, synthesizer
- synthesizer 提炼共识/分歧/新发现
- moderator 判断收敛性

### Phase 4: 结论确认（每个议题）
- 激活：moderator, synthesizer
- 生成产出物（按议题类型选择格式）
- 标记议题任务完成

### Phase 5: 产出整合
- 激活：moderator, synthesizer, recorder
- 汇总到 `docs/discussions/{project_name}-summary.md`

### 通信协议

| 阶段 | 发送者 | 接收者 | 格式前缀 |
|------|--------|--------|---------|
| 广播议题 | moderator | 全体 | `[TOPIC]` |
| 提交观点 | expert/critic | moderator | `[OPINION]` |
| 广播观点 | moderator | 全体 | `[REVIEW]` |
| 交叉回应 | 任何成员 | moderator | `[RESPONSE]` |
| 轮次总结 | synthesizer | moderator | `[SUMMARY]` |
| 裁定通知 | moderator | 全体 | `[DECISION]` |

## 产出物格式

按议题类型自动选择：
- 技术决策 → ADR 格式（`docs/decisions/NNN-{topic}.md`）
- 需求研讨 → 方案对比矩阵（`docs/discussions/{topic}-comparison.md`）
- 头脑风暴 → 创意清单+优先级（`docs/discussions/{topic}-ideas.md`）

讨论过程文档由 recorder 维护：`docs/discussions/{project_name}-{topic}.md`

## 兼容性

### 不需要修改的 skill
- team-save：正常读取 discuss 成员的 prompt
- team-list：只解析 YAML 元数据
- team-delete：只删文件

### 需要微调的 skill
- team-load SKILL.md：S-4 lead 映射补充 `discuss → moderator`

### 配置保存
template 格式新增 `max_rounds` 字段，仅 discuss 类型存在。

## 改动清单

| 文件 | 操作 | 内容 |
|------|------|------|
| team-init/SKILL.md | 编辑 | 新增类型映射、Q4.5 |
| team-init/references/role-catalog.md | 编辑 | 新增 discuss 角色表 |
| team-init/references/discuss/workflow.md | 新建 | 轮次制讨论工作流 |
| team-init/references/discuss/roles/moderator.md | 新建 | 主持人角色定义 |
| team-init/references/discuss/roles/domain-expert.md | 新建 | 领域专家角色定义 |
| team-init/references/discuss/roles/critic.md | 新建 | 批判者角色定义 |
| team-init/references/discuss/roles/synthesizer.md | 新建 | 综合提炼者角色定义 |
| team-init/references/discuss/roles/recorder.md | 新建 | 记录员角色定义 |
| team-load/SKILL.md | 编辑 | S-4 映射补充 1 行 |
