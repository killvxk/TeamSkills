#!/usr/bin/env bash
# lint-roles.sh — TeamSkill 角色定义文件格式校验脚本
# 检查 references/ 下所有角色文件是否符合 5 板块结构
#
# 用法（从项目根目录或任意位置运行均可）:
#   bash skills/team-init/scripts/lint-roles.sh              # 检查所有核心角色
#   bash skills/team-init/scripts/lint-roles.sh dev          # 仅检查 dev 团队
#   bash skills/team-init/scripts/lint-roles.sh dev/roles/pm.md  # 检查单个文件
#   bash skills/team-init/scripts/lint-roles.sh --extensions # 检查扩展角色

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 计数器
ERRORS=0
WARNINGS=0
PASSED=0
TOTAL=0

# 自动定位 references 目录（相对于脚本自身位置）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROLES_ROOT="$SKILL_ROOT/references"

# Lead 角色列表（需要额外检查管理段）
LEAD_ROLES="pm.md test-manager.md re-lead.md debug-lead.md security-lead.md captain.md ops-manager.md moderator.md"

# 检查是否为 Lead 角色
is_lead() {
    local filename
    filename=$(basename "$1")
    echo "$LEAD_ROLES" | grep -qw "$filename"
}

# 错误输出
error() {
    echo -e "  ${RED}ERROR${NC}: $1"
    ERRORS=$((ERRORS+1))
}

# 警告输出
warn() {
    echo -e "  ${YELLOW}WARN${NC}:  $1"
    WARNINGS=$((WARNINGS+1))
}

# 通过输出
pass() {
    echo -e "  ${GREEN}PASS${NC}:  $1"
}

# 检查单个角色文件
lint_role() {
    local file="$1"
    local filename
    filename=$(basename "$file")
    local line_count
    line_count=$(wc -l < "$file")

    TOTAL=$((TOTAL+1))

    echo -e "\n${CYAN}检查${NC}: $file (${line_count} 行)"

    # ERROR: 文件为空
    if [ "$line_count" -eq 0 ]; then
        error "文件为空"
        return
    fi

    # ERROR: 文件内容过少
    if [ "$line_count" -lt 20 ]; then
        error "文件内容不足 20 行，角色定义过于单薄"
        return
    fi

    local has_error=0

    # ERROR: 缺少 <role> 段
    if ! grep -q '<role>' "$file"; then
        error "缺少 <role> 标签"
        has_error=1
    fi
    if ! grep -q '</role>' "$file"; then
        error "缺少 </role> 闭合标签"
        has_error=1
    fi

    # ERROR: 缺少 <rules> 段
    if ! grep -q '<rules>' "$file"; then
        error "缺少 <rules> 标签"
        has_error=1
    fi
    if ! grep -q '</rules>' "$file"; then
        error "缺少 </rules> 闭合标签"
        has_error=1
    fi

    # WARN: 缺少 <deliverables> 段
    if ! grep -q '<deliverables>' "$file"; then
        warn "缺少 <deliverables> 标签（技术交付物是价值最高的板块）"
    else
        pass "<deliverables> 存在"
    fi

    # WARN: 缺少 <collaboration> 段
    if ! grep -q '<collaboration>' "$file"; then
        warn "缺少 <collaboration> 标签"
    else
        pass "<collaboration> 存在"
    fi

    # WARN: 缺少 <metrics> 段
    if ! grep -q '<metrics>' "$file"; then
        warn "缺少 <metrics> 标签（成功指标）"
    else
        pass "<metrics> 存在"
    fi

    # WARN: 缺少核心使命段
    if ! grep -q '## 核心使命\|## Core Mission' "$file"; then
        warn "缺少 '## 核心使命' 标题"
    fi

    # WARN: 缺少关键规则段
    if ! grep -q '## 关键规则\|## 必须做\|### 必须做' "$file"; then
        warn "缺少 '必须做' 规则段"
    fi
    if ! grep -q '## 绝不做\|### 绝不做' "$file"; then
        warn "缺少 '绝不做' 规则段"
    fi

    # WARN: 正文内容 < 50 行
    if [ "$line_count" -lt 50 ]; then
        warn "正文内容仅 ${line_count} 行（建议 80-120 行）"
    fi

    # WARN: 执行角色超过 200 行（可能过于冗长）
    if ! is_lead "$file" && [ "$line_count" -gt 200 ]; then
        warn "执行角色 ${line_count} 行，超过建议上限 200 行"
    fi

    # Lead 角色额外检查
    if is_lead "$file"; then
        # WARN: Lead 角色缺少 <team_management> 段
        if ! grep -q '<team_management>' "$file"; then
            warn "Lead 角色缺少 <team_management> 标签"
        else
            pass "<team_management> 存在"
        fi

        # WARN: Lead 角色缺少 <task_management> 段
        if ! grep -q '<task_management>' "$file"; then
            warn "Lead 角色缺少 <task_management> 标签"
        else
            pass "<task_management> 存在"
        fi

        # WARN: Lead 角色缺少 <project_completion> 段
        if ! grep -q '<project_completion>' "$file"; then
            warn "Lead 角色缺少 <project_completion> 标签"
        else
            pass "<project_completion> 存在"
        fi

        # WARN: Lead 角色缺少 <workflow> 段
        if ! grep -q '<workflow>' "$file"; then
            warn "Lead 角色缺少 <workflow> 标签"
        else
            pass "<workflow> 存在"
        fi
    fi

    # 检查角色定位开头（应以 "你是" 开头的段落）
    if ! head -10 "$file" | grep -q '你是'; then
        warn "前 10 行未找到角色定位语句（应以 '你是...' 开头）"
    fi

    # 标签闭合检查
    local open_tags close_tags
    open_tags=$(grep -c '<[a-z_]*>' "$file" 2>/dev/null || echo 0)
    close_tags=$(grep -c '</[a-z_]*>' "$file" 2>/dev/null || echo 0)
    if [ "$open_tags" -ne "$close_tags" ]; then
        warn "开标签 (${open_tags}) 与闭标签 (${close_tags}) 数量不一致"
    fi

    if [ "$has_error" -eq 0 ]; then
        PASSED=$((PASSED+1))
    fi
}

# 主流程
main() {
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  TeamSkill 角色定义格式校验 (lint-roles)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local target="${1:-}"
    local files=()

    if [ "$target" = "--extensions" ]; then
        # 检查扩展角色
        local ext_root="$ROLES_ROOT/extensions"
        if [ ! -d "$ext_root" ]; then
            echo -e "${RED}扩展角色目录不存在: $ext_root${NC}"
            exit 1
        fi
        while IFS= read -r line; do
            [ -n "$line" ] && files+=("$line")
        done < <(find "$ext_root" -name "*.md" -not -name "*catalog*" 2>/dev/null | sort)
    elif [ -z "$target" ]; then
        # 检查所有核心角色（排除 extensions/ 和 shared/）
        while IFS= read -r line; do
            [ -n "$line" ] && files+=("$line")
        done < <(find "$ROLES_ROOT" -path "*/roles/*.md" -not -path "*/extensions/*" 2>/dev/null | sort)
    elif [ -f "$target" ]; then
        # 检查单个文件（支持绝对路径和相对路径）
        files+=("$target")
    elif [ -d "$ROLES_ROOT/$target" ]; then
        # 检查指定团队目录
        while IFS= read -r line; do
            [ -n "$line" ] && files+=("$line")
        done < <(find "$ROLES_ROOT/$target" -path "*/roles/*.md" 2>/dev/null | sort)
    elif [ -d "$ROLES_ROOT/$target/roles" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && files+=("$line")
        done < <(find "$ROLES_ROOT/$target/roles" -name "*.md" 2>/dev/null | sort)
    elif [ -d "$ROLES_ROOT/extensions/$target" ]; then
        # 检查扩展角色的指定部门
        while IFS= read -r line; do
            [ -n "$line" ] && files+=("$line")
        done < <(find "$ROLES_ROOT/extensions/$target" -name "*.md" -not -name "*catalog*" 2>/dev/null | sort)
    else
        echo -e "${RED}找不到目标: $target${NC}"
        echo "用法: bash skills/team-init/scripts/lint-roles.sh [团队目录|文件路径|--extensions]"
        exit 1
    fi

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}未找到任何角色文件${NC}"
        echo "确认 $ROLES_ROOT 目录下存在 */roles/*.md 文件"
        exit 1
    fi

    for file in "${files[@]}"; do
        lint_role "$file"
    done

    # 汇总报告
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "  扫描完成: ${TOTAL} 个文件"
    echo -e "  ${GREEN}通过${NC}: ${PASSED}  ${RED}错误${NC}: ${ERRORS}  ${YELLOW}警告${NC}: ${WARNINGS}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    if [ "$ERRORS" -gt 0 ]; then
        echo -e "\n${RED}存在 ${ERRORS} 个错误，请修复后重新检查。${NC}"
        exit 1
    elif [ "$WARNINGS" -gt 0 ]; then
        echo -e "\n${YELLOW}存在 ${WARNINGS} 个警告，建议检查。${NC}"
        exit 0
    else
        echo -e "\n${GREEN}所有角色文件格式正确！${NC}"
        exit 0
    fi
}

main "$@"
