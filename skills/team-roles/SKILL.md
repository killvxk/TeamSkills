---
name: team-roles
description: |
  This skill should be used when the user asks to "安装远程角色", "team-roles add",
  "team-roles list", "添加远程角色", "管理远程角色", "从 GitHub 安装角色",
  "team-roles update", "team-roles remove", "team-roles search",
  "install remote roles", "add remote roles", "远程角色管理",
  "list remote roles", "update remote roles", "remove remote roles".
  从 GitHub 仓库、单文件 URL 或 npx 包安装扩展角色到项目级缓存 .team-roles/。
version: 0.5.0
---

# 远程角色管理（team-roles）

管理项目级远程角色缓存，支持从 GitHub 仓库、单文件 URL、npx 包三种来源安装角色文件，与 `/team-init`、`/team-load`、`/team-save` 无缝集成。

## 路径约定

- `{work_dir}`：用户当前工作目录（项目根目录）
- `.team-roles/`：`{work_dir}/.team-roles/`，远程角色缓存根目录
- `roles-lock.json`：`{work_dir}/.team-roles/roles-lock.json`，锁文件（唯一数据源）

缓存目录结构：
```
.team-roles/
├── roles-lock.json           # 锁文件
├── {repo-name}/              # GitHub repo 源
├── _singles/                 # 单文件 URL 源
└── _npx/{package-name}/      # npx 包源
```

---

## 子命令路由

| 参数 | 路由 |
|------|------|
| `add <url>` 或 `add npx:<pkg>` | → `add` |
| `list` | → `list` |
| `search <keyword>` | → `search` |
| `update [repo-name]` | → `update` |
| `remove <role-code>` | → `remove` |
| 无参数 | → 打印使用说明 |

---

## `add` — 安装远程角色

### 源类型自动检测

```
参数以 "npx:" 开头       → sourceType = "npx"
参数匹配 github.com      → sourceType = "github-repo"
其他（含 .md 结尾）       → sourceType = "file-url"
```

### .gitignore 自动追加

首次创建 `.team-roles/` 目录时，检查并追加 `.team-roles/` 到 `.gitignore`。

### 安装流程

按 `sourceType` 分支执行，详细步骤参考 **`references/add-flows.md`**：

- **A1. GitHub Repo**：`git clone --depth 1` → 检测 manifest（`team-roles.json`）→ 扫描角色文件 → 5-Block 验证 → 用户选择 → 冲突检测 → 复制到 `.team-roles/{repo-name}/` → 更新 lock → 清理临时目录
- **A2. 单文件 URL**：`WebFetch` 下载 → 5-Block 验证 → 展示摘要确认 → 写入 `_singles/` → 更新 lock
- **A3. npx 包**：三级回退安装（`npx skills add` → git clone → 报错）→ 扫描 `.md` 文件 → 剥离 YAML frontmatter → 标记 unverified → 用户选择 → 写入 `_npx/` → 更新 lock

### 冲突检测

角色代号与已安装角色重复时，提示 3 个选项：
1. "覆盖已有" — 替换 lock 条目和文件
2. "跳过此角色" — 不安装
3. "重命名为 {repo}-{code}" — 保留两者

### `--roles=a,b` 参数

跳过交互，直接安装指定代号的角色。

---

## 5-Block 验证算法

| 标签对 | 权重 |
|--------|------|
| `<role>` + `</role>` | **必须** |
| `<rules>` + `</rules>` | **必须** |
| `<deliverables>` + `</deliverables>` | 可选 |
| `<collaboration>` + `</collaboration>` | 可选 |
| `<metrics>` + `</metrics>` | 可选 |

- 两个必须标签对均存在 → `verified: true`
- 任一必须标签对缺失 → `verified: false`（unverified）
- verified 但缺少可选标签 → 仍为 verified，输出 warning

---

## `list` — 列出已安装角色

从 `roles-lock.json` 读取，格式化表格输出：

```
| 代号           | 来源             | 类型        | 状态         | 安装时间   |
|----------------|-----------------|------------|-------------|------------|
| ai-engineer    | user/my-roles   | github-repo | ✓ verified  | 2026-03-18 |
| vite-skill     | antfu/skills    | npx         | ⚠ unverified | 2026-03-18 |

共 {N} 个角色，来自 {M} 个源
```

空状态提示：`暂无已安装的远程角色。使用 team-roles add <url> 安装。`

---

## `search` — 搜索已安装角色

对 `code`、`displayName`、`department`、`source` 四个字段做不区分大小写的关键词匹配。输出格式同 `list`。

---

## `update` — 更新角色

按源类型分别处理，详细步骤参考 **`references/update-flows.md`**：

- **GitHub repo**：clone → 比对 commitHash → 逐角色覆盖 + 重新 5-Block 验证 → 更新 lock
- **单文件 URL**：WebFetch 重新下载 → 内容比对 → 覆盖 + 重新验证 → 更新 lock
- **npx 包**：覆盖安装 → 重新扫描 → 覆盖缓存 → 更新 lock

每次 update 都重新运行 5-Block 验证（角色可能从 unverified 变为 verified，或反之）。

---

## `remove` — 移除角色

1. 在 `roles-lock.json` 中查找角色代号
2. 展示信息并确认删除
3. 删除缓存文件
4. 从 lock 的 `roles[]` 移除条目
5. 若该 repo 下无剩余角色 → 删除整个目录 + 从 `repos[]` 移除
6. 写入 lock

---

## 错误处理

| 场景 | 处理 |
|------|------|
| `git clone` 失败 | 报错退出，清理临时目录 |
| WebFetch 失败 | 报错退出 |
| lock 损坏 | 提示手动检查或删除后重试 |
| lock 不存在（读） | 视为空 lock |
| lock 不存在（写） | 初始化新结构 |
| npx + git 都失败 | 提示用户提供 GitHub URL |

---

## 使用说明

```
team-roles — 远程角色管理

用法：
  team-roles add <github-url>          从 GitHub 仓库安装角色
  team-roles add <file-url.md>         从单文件 URL 安装角色
  team-roles add npx:<package>         从 npx 包安装角色
  team-roles add <url> --roles=a,b     指定安装部分角色（非交互）
  team-roles list                      列出所有已安装的远程角色
  team-roles search <keyword>          搜索已安装角色
  team-roles update [repo-name]        更新指定 repo 或全部角色
  team-roles remove <role-code>        移除指定角色
```

---

## 参考资料

详细流程和 schema 定义：
- **`references/add-flows.md`** — 三种源类型的完整安装步骤（A1/A2/A3）
- **`references/update-flows.md`** — 三种源类型的完整更新步骤（U1/U2/U3）
- **`references/lock-schema.md`** — `roles-lock.json` 完整 schema、字段说明、初始化结构
