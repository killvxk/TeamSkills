# 各类型角色一览

## 1. 软件开发 (dev)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 项目经理 | pm | 否 |
| 架构师 | architect | 否 |
| 需求分析师 | analyst | 否 |
| 开发工程师 | developer | 是 |
| 测试工程师 | tester | 是 |
| 运维工程师 | ops | 是 |
| 代码审计 | auditor | 是 |
| 验收人员 | acceptor | 否 |

## 2. 软件测试 (testing)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 测试经理 | test-manager | 否 |
| 测试架构师 | test-architect | 否 |
| 功能测试工程师 | functional-tester | 是 |
| 性能测试工程师 | perf-tester | 是 |
| 安全测试工程师 | security-tester | 是 |
| 自动化测试工程师 | automation-tester | 是 |

## 3. 逆向工程 (reverse)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 逆向负责人 | re-lead | 否 |
| 静态分析师 | static-analyst | 是 |
| 动态分析师 | dynamic-analyst | 是 |
| 协议分析师 | protocol-analyst | 是 |
| 漏洞研究员 | vuln-researcher | 是 |
| 文档记录员 | documenter | 否 |

## 4. 调试/Bug修复 (debug)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 调试负责人 | debug-lead | 否 |
| 问题分析师 | issue-analyst | 是 |
| 根因分析师 | root-cause-analyst | 是 |
| 修复工程师 | fix-engineer | 是 |
| 回归测试工程师 | regression-tester | 是 |
| 代码审查员 | code-reviewer | 否 |

## 5. 安全研究 (security)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 安全负责人 | security-lead | 否 |
| 漏洞挖掘工程师 | vuln-hunter | 是 |
| 漏洞利用开发 | exploit-dev | 是 |
| 安全审计师 | security-auditor | 是 |
| 防御研究员 | defense-researcher | 否 |
| 报告编写 | report-writer | 否 |

## 6. CTF 比赛 (ctf)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 队长 | captain | 否 |
| Web安全选手 | web | 是 |
| 逆向工程选手 | reverse | 是 |
| 密码学选手 | crypto | 是 |
| PWN选手 | pwn | 是 |
| Misc选手 | misc | 是 |
| 取证选手 | forensics | 是 |

## 7. 运维 (ops)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 运维经理 | ops-manager | 否 |
| 系统工程师 | sys-engineer | 是 |
| 网络工程师 | net-engineer | 是 |
| DBA | dba | 是 |
| 监控工程师 | monitor-engineer | 是 |
| 安全运维 | security-ops | 是 |
| 自动化工程师 | automation-engineer | 是 |

## 8. 讨论/研讨 (discuss)
| 角色 | 代号 | 可多实例 |
|------|------|----------|
| 主持人 | moderator | 否 |
| 领域专家 | domain-expert | 是 |
| 批判者 | critic | 否 |
| 综合提炼者 | synthesizer | 否 |
| 记录员 | recorder | 否 |

---

## 扩展角色库

除上述 8 种团队类型的内建角色外，还可从扩展角色库中按需添加专业角色。扩展角色横跨 12 个领域共 146 个角色，详见 `extensions/extension-catalog.md`。

| 领域 | 角色数 | 示例角色 |
|------|--------|---------|
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

## 远程角色

除上述内置角色外，用户可通过 `/team-roles add` 从 GitHub 仓库、单文件 URL 或 npx 包安装额外角色。已安装的远程角色在创建团队时（问题 4.5）可选加入。

详见 `/team-roles` Skill。
