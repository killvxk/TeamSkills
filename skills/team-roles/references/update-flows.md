# `update` 子命令 — 详细更新流程

## U1. GitHub Repo 更新流程

### U1-1. 读取 lock，获取待更新 repo 列表

### U1-2. 对每个待更新 repo 执行

```bash
tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'team-roles-update')
git clone --depth 1 <repo-url> "$tmpdir"
```

若克隆失败，报告该 repo 更新失败并继续处理下一个。

### U1-3. 比对 commit hash

```bash
new_hash=$(git -C "$tmpdir" rev-parse HEAD)
```

与 lock 中 `commitHash` 比对：
- **相同** → 输出 `{repo-name}：已是最新（{hash[:8]}）`，跳过此 repo
- **不同** → 执行更新

### U1-4. 逐角色更新

对 lock 中该 repo 下的每个已安装角色（`source == repo-name`）：

1. 定位远程文件路径（根据 lock 中 `filePath` 推断在 `$tmpdir` 中的对应路径）
2. **远程文件存在** → 读取内容，覆盖本地缓存文件，重新运行 5-Block 验证，更新 lock 中 `verified` 状态
3. **远程文件不存在** → 警告：
   ```
   ⚠ 角色 {code} 在远程已删除，保留本地副本
   ```
   保留本地文件，lock 中该条目保持不变

### U1-5. 更新 lock

- `repos[].commitHash` = `new_hash`
- `repos[].updatedAt` = 当前 ISO 时间
- `roles[].updatedAt` = 当前 ISO 时间（只更新有变化的条目）
- 更新 `lastUpdated`
- 写入 lock 文件

### U1-6. 清理临时目录

```bash
rm -rf "$tmpdir"
```

### U1-7. 输出更新结果

```
{repo-name}：已更新（{old_hash[:8]} → {new_hash[:8]}）
  ✓ ai-engineer 更新（verified）
  ⚠ frontend-dev 更新（unverified）
  ⚠ old-role 在远程已删除，保留本地副本
```

---

## U2. 单文件 URL 更新流程

对所有 `sourceType: "file-url"` 的 repo 条目：

1. WebFetch 重新下载 `url`
2. 若下载失败，报告失败并跳过
3. 读取本地缓存文件内容（`{work_dir}/.team-roles/{filePath}`）
4. **内容相同** → 输出 `{code}：已是最新`
5. **内容不同** → 覆盖本地文件，重新运行 5-Block 验证，更新 lock 的 `verified`、`updatedAt`、`sizeBytes`
6. 更新 `lastUpdated`，写入 lock

---

## U3. npx 包更新流程

对所有 `sourceType: "npx"` 的 repo 条目：

1. 执行覆盖安装：
   ```bash
   npx skills install <package-name>
   ```
   若失败，尝试回退 git clone 方案（同 add-flows.md A3-2）
2. 重新扫描目标目录下的 `.md` 文件
3. 剥离 frontmatter
4. 覆盖本地缓存文件（只更新已在 lock 中记录的文件）
5. `verified` 保持 `false`（npx 来源始终 unverified）
6. 更新 lock 的 `updatedAt`、`sizeBytes`、`lastUpdated`，写入文件
