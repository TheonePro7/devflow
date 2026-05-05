#!/usr/bin/env bash
# merge-docs.sh
# Merge devflow seed docs into existing docs/ with safe merge strategies.
# CONTEXT.md: append missing glossary terms
# ADR README.md: append missing ADR index entries
# TDD docs/: write if not exists, skip if exists
#
# Usage:
#   bash scripts/merge-docs.sh          # Merge & write
#   bash scripts/merge-docs.sh --dry-run # Preview only

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

echo "=== Docs Merge ==="

# ---- CONTEXT.md merge ----
merge_context() {
  local path="docs/CONTEXT.md"

  if [ ! -f "$path" ]; then
    echo "[SKIP] $path does not exist — seed via setup first."
    return
  fi

  # Devflow's seed glossary terms (term:description pairs)
  declare -A seed_terms
  seed_terms["beads"]='Dolt-backed issue tracker。提供层级 ID (bd-xxx.y)、依赖管理、状态追踪。命令前缀: `bd`。核心命令: `bd init`, `bd create`, `bd update`, `bd close`, `bd dep add`, `bd ready`。'
  seed_terms["gitnexus"]='代码知识图谱。分析仓库构建符号索引，提供 context/impact/query 能力。命令前缀: `gitnexus` / `npx gitnexus`。核心命令: `analyze`, `context`, `impact`, `query`。'
  seed_terms["Plan-grill"]='从 brainstorming → writing-plans 之间的 HITL 关卡。用 CONTEXT.md + ADR + gitnexus 拷问设计盲点。输出: grill report 到 docs/superpowers/specs/。'
  seed_terms["PRD→beads"]='自动解析设计文档中的 "## Task:" 标题，为每个 task 创建 beads issue 并建立依赖关系。脚本: scripts/prd-to-beads.ps1 / .sh。'
  seed_terms["Git guardrails"]='PreToolUse hook。拦截危险 git 命令 (--force, reset --hard, clean -fd, branch -D, checkout .)。脚本: .claude/hooks/guardrails-git.ps1。'
  seed_terms["Merge semantics"]='安装脚本检测已有配置、增量追加而非覆盖的行为。'
  seed_terms["Idempotent"]='重复运行安装脚本产生相同结果，不会破坏已有配置。'

  # Extract existing terms from CONTEXT.md
  local -A existing_terms
  while IFS= read -r line; do
    local term
    term=$(printf '%s' "$line" | sed -n 's/^### \([^ ]*\)/\1/p')
    if [ -n "$term" ]; then
      existing_terms["$term"]=true
    fi
  done < "$path"

  # Find missing terms
  local -a missing_terms=()
  for term in "${!seed_terms[@]}"; do
    if [ "${existing_terms[$term]:-}" != true ]; then
      missing_terms+=("$term")
    fi
  done

  if [ ${#missing_terms[@]} -eq 0 ]; then
    echo "[OK] CONTEXT.md terms already up to date."
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN — Would append to $path ==="
    for term in "${missing_terms[@]}"; do echo "  + ### $term"; done
    return
  fi

  # Find insertion point (before "## Architecture Decisions")
  local insert_line
  insert_line=$(grep -n '^## Architecture Decisions' "$path" | head -1 | cut -d: -f1)
  if [ -z "$insert_line" ]; then
    insert_line=$(wc -l < "$path")
  else
    insert_line=$((insert_line - 1))
  fi

  # Build temp file with new terms inserted
  local tmpfile
  tmpfile=$(mktemp)
  sed -n "1,${insert_line}p" "$path" > "$tmpfile"
  for term in "${missing_terms[@]}"; do
    printf '\n### %s\n%s\n' "$term" "${seed_terms[$term]}" >> "$tmpfile"
  done
  sed -n "$((insert_line + 1)),\$p" "$path" >> "$tmpfile"
  mv "$tmpfile" "$path"

  echo "[OK] Appended ${#missing_terms[@]} missing term(s) to CONTEXT.md"
  for term in "${missing_terms[@]}"; do echo "  + ### $term"; done
}

# ---- ADR README.md merge ----
merge_adr() {
  local readme="docs/adr/README.md"

  if [ ! -f "$readme" ]; then
    echo "[SKIP] $readme does not exist — seed via setup first."
    return
  fi

  # Find ADR files (exclude README.md)
  local -a adr_files=()
  while IFS= read -r f; do
    adr_files+=("$(basename "$f")")
  done < <(find docs/adr/ -maxdepth 1 -name '*.md' ! -name 'README.md' | sort)

  if [ ${#adr_files[@]} -eq 0 ]; then
    echo "[SKIP] No ADR files to index."
    return
  fi

  # Extract existing index entries (markdown links)
  local -A existing_links
  while IFS= read -r line; do
    local linked_file
    linked_file=$(printf '%s' "$line" | sed -n 's/.*](\([^)]*\))/\1/p')
    if [ -n "$linked_file" ]; then
      existing_links["$linked_file"]=true
    fi
  done < "$readme"

  # Find files not in index
  local -a missing_files=()
  local f
  for f in "${adr_files[@]}"; do
    if [ "${existing_links[$f]:-}" != true ]; then
      missing_files+=("$f")
    fi
  done

  if [ ${#missing_files[@]} -eq 0 ]; then
    echo "[OK] ADR index already up to date."
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN — Would append to $readme ==="
    for f in "${missing_files[@]}"; do echo "  + $f"; done
    return
  fi

  # Append missing entries
  for f in "${missing_files[@]}"; do
    printf '\n- [%s](%s)' "$f" "$f" >> "$readme"
  done
  echo "" >> "$readme"

  echo "[OK] Appended ${#missing_files[@]} missing ADR entry/entries to README.md"
  for f in "${missing_files[@]}"; do echo "  + $f"; done
}

# ---- TDD docs merge ----
merge_tdd() {
  local tdd_dir="docs/tdd"
  local template="$tdd_dir/testing-philosophy.md"

  if [ -d "$tdd_dir" ]; then
    local existing_count
    existing_count=$(find "$tdd_dir" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
    if [ "$existing_count" -gt 0 ]; then
      echo "[SKIP] TDD docs already exist — user modifications respected."
      return
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN — Would create $template ==="
    return
  fi

  mkdir -p "$tdd_dir"

  cat > "$template" << 'TDDEOF'
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** — tests should verify outcomes, not internal details
2. **Write tests before code** — TDD cycle: Red → Green → Refactor
3. **One assertion per test** — each test should verify one behavior
4. **Tests are documentation** — a good test suite describes how the system works

## Test Structure

```
describe('feature')
  describe('scenario')
    it('should behave as expected')
```

## Coverage Goals

- Unit tests: 90%+ coverage on business logic
- Integration tests: critical paths only
- E2E tests: happy path + top 3 error scenarios
TDDEOF

  echo "[OK] Created $template with default TDD docs."
}

# --- Main ---
merge_context
merge_adr
merge_tdd
