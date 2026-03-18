# `add` 子命令 — 详细安装流程

## A1. GitHub Repo 安装流程

**触发条件**：`sourceType = "github-repo"`

### A1-1. 创建临时目录并克隆

```bash
tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'team-roles')
git clone --depth 1 <repo-url> "$tmpdir"
```

若 `git clone` 失败（网络错误、仓库不存在等），报错并退出：
```
错误：无法克隆仓库 <repo-url>
原因：<git 错误信息>
请检查 URL 是否正确，以及网络连接是否正常。
```

### A1-2. 检测 manifest

检查 `$tmpdir/team-roles.json` 是否存在：

- **有 manifest** → 按 manifest 读取角色列表、分类、路径：
  ```json
  {
    "name": "my-roles",
    "description": "角色集合描述",
    "roles": [
      { "code": "ai-engineer", "path": "custom-dir/ai-engineer.md", "department": "engineering", "description": "AI/ML 工程师" }
    ]
  }
  ```
  - `repo-name` = manifest 的 `name` 字段（若存在），否则用 URL 最后一段
  - 角色列表 = manifest 的 `roles[]`

- **无 manifest** → 扫描 `$tmpdir/roles/` 目录下所有 `.md` 文件：
  ```bash
  find "$tmpdir/roles" -name "*.md" -type f 2>/dev/null
  ```
  若 `roles/` 目录也不存在，扫描 `$tmpdir` 根目录下的 `.md` 文件（排除 `README.md`）。
  - 角色代号 = 文件名去 `.md` 后缀
  - 部门 = `_uncategorized`
  - `repo-name` = URL 最后一段

### A1-3. 5-Block 验证（对每个候选角色文件）

读取角色文件内容，执行验证（详见 SKILL.md "5-Block 验证算法"章节）。

### A1-4. 展示候选角色列表

```
发现 {N} 个角色（来源：{repo-url}）：

| 代号              | 文件路径                     | 状态         | 摘要（前 3 行）         |
|-------------------|------------------------------|-------------|------------------------|
| ai-engineer       | roles/ai-engineer.md         | ✓ verified  | AI/ML 工程师，负责...   |
| frontend-dev      | roles/frontend-dev.md        | ⚠ unverified | 前端开发，专注 React... |
```

### A1-5. 用户选择要安装的角色

- **有 `--roles=a,b` 参数** → 非交互模式，直接安装指定代号的角色，跳过 AskUserQuestion
- **无 `--roles` 参数** → 使用 `AskUserQuestion` 让用户多选：

```
question: "请选择要安装的角色（可多选，或输入 'all' 安装全部）："
options: ["{code1} — {verified状态} — {摘要}", "{code2} ...", "全部安装", "取消"]
```

### A1-6. 冲突检测

对每个待安装角色，检查 `roles-lock.json` 中是否已存在相同 `code`：

- **无冲突** → 直接安装
- **有冲突** → 使用 `AskUserQuestion` 提示：

```
question: "角色代号 '{code}' 已安装（来源：{existing_source}），如何处理？"
options:
  - "覆盖已有"
  - "跳过此角色"
  - "重命名为 {repo-name}-{code}"
```

按用户选择处理：
- **覆盖已有**：替换 lock 中对应条目和文件
- **跳过**：不安装此角色
- **重命名**：以 `{repo-name}-{code}` 作为新代号安装

### A1-7. 复制文件到缓存目录

```bash
mkdir -p "{work_dir}/.team-roles/{repo-name}"
cp "$tmpdir/{role-path}" "{work_dir}/.team-roles/{repo-name}/{role-filename}"
```

### A1-8. 更新 `roles-lock.json`

读取现有 lock（不存在则初始化空结构），追加/更新条目：

1. 在 `repos[]` 中添加或更新 repo 条目：
   ```json
   {
     "name": "{repo-name}",
     "url": "{repo-url}",
     "sourceType": "github-repo",
     "commitHash": "<git -C $tmpdir rev-parse HEAD 的输出>",
     "hasManifest": true/false,
     "installedAt": "{ISO时间}",
     "updatedAt": "{ISO时间}"
   }
   ```
   获取 commit hash：
   ```bash
   git -C "$tmpdir" rev-parse HEAD
   ```

2. 在 `roles[]` 中为每个已安装角色添加条目：
   ```json
   {
     "code": "{code}",
     "displayName": "{manifest描述 或 code}",
     "source": "{repo-name}",
     "sourceType": "github-repo",
     "filePath": "{repo-name}/{filename}",
     "department": "{department 或 _uncategorized}",
     "verified": true/false,
     "sizeBytes": <文件大小>,
     "installedAt": "{ISO时间}",
     "updatedAt": "{ISO时间}"
   }
   ```

3. 更新顶层 `lastUpdated` 字段

4. 将 lock 对象序列化写入 `{work_dir}/.team-roles/roles-lock.json`（格式化 JSON，缩进 2 空格）

### A1-9. 清理临时目录

```bash
rm -rf "$tmpdir"
```

### A1-10. 输出安装结果

```
已安装 {N} 个角色到 .team-roles/{repo-name}/：
  ✓ ai-engineer（verified）
  ⚠ frontend-dev（unverified）
```

---

## A2. 单文件 URL 安装流程

**触发条件**：`sourceType = "file-url"`

### A2-1. 下载文件

使用 WebFetch 工具下载 URL 内容。

若 WebFetch 失败，报错：
```
错误：无法下载 <url>
请检查 URL 是否正确以及网络连接是否正常。
```

### A2-2. 5-Block 验证

对下载内容执行验证（详见 SKILL.md "5-Block 验证算法"章节）。

### A2-3. 提取角色代号

`role-code` = URL 最后一段，去 `.md` 后缀（例如：`https://example.com/roles/reviewer.md` → `reviewer`）

若 URL 不以 `.md` 结尾，使用 URL 最后一段作为代号。

### A2-4. 展示摘要并确认

展示文件前 20 行，使用 `AskUserQuestion` 让用户确认安装：

```
question: "即将安装角色 '{role-code}'（{verified状态}）。
---（前 20 行预览）---
{内容前20行}
---
确认安装？"
options: ["确认安装", "取消"]
```

### A2-5. 冲突检测

同 A1-6，检查 `roles-lock.json` 中是否存在相同 code。

### A2-6. 写入缓存

```bash
mkdir -p "{work_dir}/.team-roles/_singles"
```

将下载内容写入 `{work_dir}/.team-roles/_singles/{role-code}.md`（使用 Write 工具）。

### A2-7. 更新 `roles-lock.json`

1. 在 `repos[]` 中添加条目：
   ```json
   {
     "name": "{role-code}",
     "url": "{file-url}",
     "sourceType": "file-url",
     "commitHash": null,
     "hasManifest": false,
     "installedAt": "{ISO时间}",
     "updatedAt": "{ISO时间}"
   }
   ```

2. 在 `roles[]` 中添加条目：
   ```json
   {
     "code": "{role-code}",
     "displayName": "{role-code}",
     "source": "{file-url}",
     "sourceType": "file-url",
     "filePath": "_singles/{role-code}.md",
     "department": "_uncategorized",
     "verified": true/false,
     "sizeBytes": <内容字节数>,
     "installedAt": "{ISO时间}",
     "updatedAt": "{ISO时间}"
   }
   ```

3. 更新顶层 `lastUpdated`，写入文件

### A2-8. 输出结果

```
已安装角色 '{role-code}'（{verified状态}）到 .team-roles/_singles/
```

---

## A3. npx 包安装流程

**触发条件**：`sourceType = "npx"`，包名 = 去掉 `npx:` 前缀后的字符串

### A3-1. 创建临时目录

```bash
tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'team-roles-npx')
```

### A3-2. 三级回退安装

**优先（第1级）：npx skills add**

```bash
npx skills add <package-name> 2>&1
```

- 若成功，定位安装目录（优先检查 `{work_dir}/.claude/skills/`，其次 `~/.claude/skills/`）
- 跳至 A3-3

**回退（第2级）：git clone**

若 `npx skills` 命令不存在或执行失败：

- 从包名推断 GitHub URL：
  - `user/repo@skill` 格式 → `https://github.com/user/repo`，目标子目录 = `skill`
  - `user/repo` 格式 → `https://github.com/user/repo`，扫描根目录
  - 纯包名（如 `my-pkg`）→ 无法推断，跳至第3级

```bash
git clone --depth 1 "https://github.com/{user}/{repo}" "$tmpdir"
```

- 若指定了子目录（`@skill` 部分），定位到 `$tmpdir/{skill}/` 目录

**失败（第3级）：报错**

若两种方式都失败：

```
错误：无法安装 npx 包 '{package-name}'
- npx skills 命令不可用
- 无法推断 GitHub 仓库 URL

请直接提供 GitHub 仓库 URL，使用：
  team-roles add https://github.com/{user}/{repo}
```

### A3-3. 扫描并剥离 frontmatter

扫描安装/克隆目录下所有 `.md` 文件（包括子目录），对每个文件：

**Frontmatter 剥离规则**：
- 检查文件是否以 `---` 开头（第一行）
- 若是，找到第二个 `---`，移除两者之间（含两行 `---`）的全部内容
- 保留 `---` 之后的正文

### A3-4. 验证与选择

- 所有 npx 来源文件一律标记为 `unverified`（不运行 5-Block 验证）
- 展示发现的文件列表，使用 `AskUserQuestion` 让用户选择要安装的文件

### A3-5. 冲突检测

同 A1-6，对每个待安装角色检查代号冲突。

### A3-6. 复制到缓存目录

```bash
pkg_dir_name=$(echo "{package-name}" | tr '/:@' '-')
mkdir -p "{work_dir}/.team-roles/_npx/{pkg_dir_name}"
cp "{source-file}" "{work_dir}/.team-roles/_npx/{pkg_dir_name}/{filename}"
```

### A3-7. 更新 `roles-lock.json`

1. 在 `repos[]` 中添加条目：
   ```json
   {
     "name": "{pkg_dir_name}",
     "url": "{package-name}",
     "sourceType": "npx",
     "commitHash": null,
     "hasManifest": false,
     "installedAt": "{ISO时间}",
     "updatedAt": "{ISO时间}"
   }
   ```

2. 在 `roles[]` 中为每个安装的文件添加条目：
   ```json
   {
     "code": "{文件名去.md}",
     "displayName": "{文件名去.md}",
     "source": "{package-name}",
     "sourceType": "npx",
     "filePath": "_npx/{pkg_dir_name}/{filename}",
     "department": "_uncategorized",
     "verified": false,
     "sizeBytes": <文件大小>,
     "installedAt": "{ISO时间}",
     "updatedAt": "{ISO时间}"
   }
   ```

3. 更新 `lastUpdated`，写入文件

### A3-8. 清理临时目录（仅回退方案使用了临时目录时）

```bash
rm -rf "$tmpdir"
```

### A3-9. 输出结果

```
已安装 {N} 个角色到 .team-roles/_npx/{pkg_dir_name}/（均为 unverified）：
  ⚠ {role1}
  ⚠ {role2}
```
