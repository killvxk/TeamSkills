# `roles-lock.json` Schema

## 完整结构

```json
{
  "version": "1.0",
  "lastUpdated": "2026-03-18T12:00:00Z",
  "repos": [
    {
      "name": "my-roles",
      "url": "https://github.com/user/my-roles",
      "sourceType": "github-repo",
      "commitHash": "abc123def456",
      "hasManifest": true,
      "installedAt": "2026-03-18T12:00:00Z",
      "updatedAt": "2026-03-18T12:00:00Z"
    },
    {
      "name": "reviewer",
      "url": "https://raw.githubusercontent.com/user/roles/main/reviewer.md",
      "sourceType": "file-url",
      "commitHash": null,
      "hasManifest": false,
      "installedAt": "2026-03-18T12:00:00Z",
      "updatedAt": "2026-03-18T12:00:00Z"
    },
    {
      "name": "antfu-skills-vite",
      "url": "antfu/skills@vite",
      "sourceType": "npx",
      "commitHash": null,
      "hasManifest": false,
      "installedAt": "2026-03-18T12:00:00Z",
      "updatedAt": "2026-03-18T12:00:00Z"
    }
  ],
  "roles": [
    {
      "code": "ai-engineer",
      "displayName": "AI 工程师",
      "source": "my-roles",
      "sourceType": "github-repo",
      "filePath": "my-roles/ai-engineer.md",
      "department": "engineering",
      "verified": true,
      "sizeBytes": 3200,
      "installedAt": "2026-03-18T12:00:00Z",
      "updatedAt": "2026-03-18T12:00:00Z"
    },
    {
      "code": "custom-reviewer",
      "displayName": "Custom Reviewer",
      "source": "https://raw.githubusercontent.com/user/roles/main/reviewer.md",
      "sourceType": "file-url",
      "filePath": "_singles/custom-reviewer.md",
      "department": "_uncategorized",
      "verified": true,
      "sizeBytes": 2100,
      "installedAt": "2026-03-18T12:00:00Z",
      "updatedAt": "2026-03-18T12:00:00Z"
    },
    {
      "code": "vite-skill",
      "displayName": "Vite Skill",
      "source": "antfu/skills@vite",
      "sourceType": "npx",
      "filePath": "_npx/antfu-skills-vite/SKILL.md",
      "department": "_uncategorized",
      "verified": false,
      "sizeBytes": 1500,
      "installedAt": "2026-03-18T12:00:00Z",
      "updatedAt": "2026-03-18T12:00:00Z"
    }
  ]
}
```

## 字段说明

### 顶层字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `version` | string | Schema 版本号，当前为 `"1.0"` |
| `lastUpdated` | string | ISO 8601 时间戳，任何写操作后更新 |
| `repos` | array | 来源仓库/URL 列表 |
| `roles` | array | 已安装角色列表 |

### `repos[]` 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | 来源标识（repo 名或角色代号） |
| `url` | string | 来源 URL |
| `sourceType` | enum | `"github-repo"` \| `"file-url"` \| `"npx"` |
| `commitHash` | string\|null | Git commit hash（仅 github-repo），file-url 和 npx 为 null |
| `hasManifest` | boolean | 是否有 `team-roles.json` manifest |
| `installedAt` | string | 首次安装时间 |
| `updatedAt` | string | 最后更新时间 |

### `roles[]` 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | string | 角色代号（全局唯一） |
| `displayName` | string | 显示名称（来自 manifest 或同 code） |
| `source` | string | 所属来源标识（对应 repos[].name 或完整 URL） |
| `sourceType` | enum | `"github-repo"` \| `"file-url"` \| `"npx"` |
| `filePath` | string | 相对于 `.team-roles/` 的文件路径 |
| `department` | string | 部门分类（来自 manifest，默认 `_uncategorized`） |
| `verified` | boolean | 是否通过 5-Block 格式验证 |
| `sizeBytes` | number | 文件大小（字节） |
| `installedAt` | string | 首次安装时间 |
| `updatedAt` | string | 最后更新时间 |

## `sourceType` 枚举值

| 值 | 说明 |
|----|------|
| `"github-repo"` | GitHub 仓库来源 |
| `"file-url"` | 单文件 URL 来源 |
| `"npx"` | npx 包来源 |
| `"registry"` | （v2 预留）注册中心来源 |

## 预留字段（v2+）

| 字段 | 版本 | 说明 |
|------|------|------|
| `convertedFrom` | v2 | AI 转换来源标识 |
| `roleVersion` | v4 | 角色语义版本号（注意与顶层 `version` 区分） |

## 初始化空结构

首次写入时使用：

```json
{
  "version": "1.0",
  "lastUpdated": "{当前ISO时间}",
  "repos": [],
  "roles": []
}
```
