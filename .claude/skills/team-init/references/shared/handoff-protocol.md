# 跨角色交接协议 (Handoff Protocol)

> 本协议定义了 TeamSkill 所有团队类型中，角色间工作交接的标准流程。
> 每个角色的 `<collaboration>` 段应遵循本协议的通信规范。

---

## 交接三要素

每次角色间交接必须包含以下三要素，缺一不可：

| 要素 | 说明 | 示例 |
|------|------|------|
| **交付物** | 已完成的具体产出物，附文件路径或内容 | `docs/design/design.md 已完成` |
| **验收标准** | 下游角色如何判断交付物合格 | `覆盖全部 5 个 API 端点` |
| **上下文传递** | 影响下游工作的关键决策、约束或遗留问题 | `数据库选用 PostgreSQL，原因见 ADR-003` |

---

## 标准交接消息格式

角色间通过 SendMessage 进行交接时，使用以下格式：

```
SendMessage:
  type: "message"
  recipient: "@{下游角色名}"
  content: |
    ## 交接：{交接事项简述}

    ### 交付物
    - {交付物 1}: {文件路径或描述}
    - {交付物 2}: ...

    ### 验收标准
    - [ ] {标准 1}
    - [ ] {标准 2}

    ### 上下文
    - {关键决策或约束}
    - {已知风险或遗留问题}

    ### 阻塞项（如有）
    - {尚未解决的问题，需要下游角色注意}
  summary: "{一句话摘要}"
```

---

## 交接确认机制

下游角色收到交接后，必须在开始工作前回复确认：

### 确认通过

```
SendMessage:
  type: "message"
  recipient: "@{上游角色名}"
  content: |
    ## 确认接收：{交接事项}

    交付物已审查，验收标准明确，开始执行。
    预计完成时间：{估计}
  summary: "确认接收，开始执行"
```

### 退回补充

```
SendMessage:
  type: "message"
  recipient: "@{上游角色名}"
  content: |
    ## 退回：{交接事项}

    ### 需要补充
    - {缺失项 1}: {具体描述}
    - {缺失项 2}: ...

    请补充后重新交接。
  summary: "退回，需补充 {N} 项"
```

---

## 阶段切换门禁

Lead 角色在推进到下一个工作流阶段前，必须确认以下检查清单：

```markdown
## 阶段切换检查清单: Phase {N} → Phase {N+1}

### 当前阶段收口
- [ ] 所有该阶段任务状态为 completed（使用 TaskList 验证）
- [ ] 关键交付物已生成并保存到约定路径
- [ ] 无未解决的阻塞项（或已记录为风险并制定应对方案）

### 下一阶段就绪
- [ ] 下一阶段的前置交付物已就绪（如：设计文档、需求文档）
- [ ] 下一阶段所需角色已就位（如需招募新角色，先招募再切换）
- [ ] 下一阶段的任务已创建（使用 TaskCreate）并分配负责人

### 团队通知
- [ ] 向所有受影响成员发送阶段切换通知
- [ ] 通知内容包含：新阶段目标、各角色职责、关键时间节点
```

---

## 跨阶段交接矩阵

以下是典型团队类型的阶段间交接关系：

### dev 团队

| 上游阶段 | 下游阶段 | 交接角色 | 交付物 |
|---------|---------|---------|--------|
| Phase 1 需求 | Phase 2 设计 | analyst → architect | `docs/requirements.md` |
| Phase 2 设计 | Phase 3 开发 | architect → developer | `docs/design/design.md` |
| Phase 3 开发 | Phase 4 测试 | developer → tester | PR + 单测报告 |
| Phase 3 开发 | 审计 | developer → auditor | PR 链接 + 代码审计请求 |
| Phase 4 测试 | 验收 | tester → acceptor | 测试报告 |
| 验收通过 | Phase 5 部署 | acceptor → ops | 验收报告 + 部署授权 |

### testing 团队

| 上游 | 下游 | 交接角色 | 交付物 |
|------|------|---------|--------|
| 测试策略 | 用例设计 | test-architect → functional-tester | 测试策略文档 |
| 用例设计 | 自动化 | functional-tester → automation-tester | 手工测试用例 |
| 功能测试 | 性能测试 | functional-tester → perf-tester | 功能测试通过报告 |
| 功能测试 | 安全测试 | functional-tester → security-tester | 功能测试通过报告 |

### debug 团队

| 上游 | 下游 | 交接角色 | 交付物 |
|------|------|---------|--------|
| 问题分析 | 根因定位 | issue-analyst → root-cause-analyst | 问题分析报告 |
| 根因定位 | 修复实现 | root-cause-analyst → fix-engineer | 根因分析报告 |
| 修复实现 | 代码审查 | fix-engineer → code-reviewer | 修复 PR |
| 修复实现 | 回归测试 | fix-engineer → regression-tester | 修复 PR + 回归范围 |

---

## 阻塞升级协议

当角色间交接遇到阻塞时，按以下流程升级：

```
1. 直接沟通（第 1 轮）
   → 通过 SendMessage 直接联系对方，说明需求

2. 等待超时（第 2 轮仍无响应）
   → 通过 SendMessage 通知 Lead，说明：
     - 等待谁的什么内容
     - 已等待多长时间
     - 对当前工作的影响

3. Lead 干预
   → Lead 判断情况后：
     a) 催促对方角色完成
     b) 重新分配任务给其他角色
     c) 调整计划，跳过或延后该项工作
     d) 如对方角色无响应，招募替代角色

4. 升级记录
   → Lead 在计划文件中记录阻塞事件和处理结果
```

---

## 完工交接协议

当角色完成所有分配任务后：

```
SendMessage:
  type: "message"
  recipient: "@{Lead 角色名}"
  content: |
    ## 完工报告

    ### 已完成任务
    - {任务 1}: {完成状态和产出物}
    - {任务 2}: ...

    ### 产出物清单
    - {文件路径 1}: {描述}
    - {文件路径 2}: ...

    ### 遗留事项
    - {如有未完成或需后续关注的事项}

    已无待处理工作，等待进一步指示或解散。
  summary: "所有任务完成，提交完工报告"
```

Lead 确认后，可发送 `shutdown_request` 解散该角色。
