# Project Context — Ubiquitous Language

## Project

devflow — Claude Code 开发工作流编排器。3 阶段（Setup → Develop → Finish）增强 superpowers 管道。

## Domain Glossary

### Phase 1 (Setup)
项目级一次性初始化。运行 beads init + gitnexus analyze + docs seed + guardrails 配置。
由 setup.ps1/setup.sh 或 SessionStart hook 自动检测触发。

### Phase 2 (Develop)
会话级开发循环。委托 superpowers 14-skill 管道执行 brainstorming → grill → plans → implementation → review → finish。
devflow 在定义点注入 beads、gitnexus、grill、PRD→beads、TDD docs。

### Phase 3 (Finish)
会话级收尾。beads close 当前会话 issues + 生成 session report。

### beads
Dolt-backed issue tracker。提供层级 ID (bd-xxx.y)、依赖管理、状态追踪。
命令前缀: `bd`。核心命令: `bd init`, `bd create`, `bd update`, `bd close`, `bd dep add`, `bd ready`。

### gitnexus
代码知识图谱。分析仓库构建符号索引，提供 context/impact/query 能力。
命令前缀: `gitnexus` / `npx gitnexus`。核心命令: `analyze`, `context`, `impact`, `query`。

### Plan-grill
从 brainstorming → writing-plans 之间的 HITL 关卡。用 CONTEXT.md + ADR + gitnexus 拷问设计盲点。
输出: grill report 到 docs/superpowers/specs/。

### PRD→beads
自动解析设计文档中的 "## Task:" 标题，为每个 task 创建 beads issue 并建立依赖关系。
脚本: scripts/prd-to-beads.ps1 / .sh。

### Git guardrails
PreToolUse hook。拦截危险 git 命令 (--force, reset --hard, clean -fd, branch -D, checkout .)。
脚本: .claude/hooks/guardrails-git.ps1。

### SIGSEGV (gitnexus)
已知问题。gitnexus 在 Windows/bash (Node 22) 下 tree-sitter 原生模块 crash，exit code 139。
不影响 Phase 1 其他步骤。后续版本修复。

## Architecture Decisions

详见 [docs/adr/](adr/)：

- 0001 — Use devflow 3-Phase Orchestration (accepted)

## External Systems

- superpowers (obra/superpowers) — 14-skill pipeline
- beads (gastownhall/beads) — issue tracker
- gitnexus (npm) — code knowledge graph
- autoresearch (uditgoenka/autoresearch) — autonomous iteration loop
- mattpocock/skills — pattern source (grill, TDD docs, guardrails, CONTEXT.md, ADR)

## Conventions

- SKILL.md 中的注入点编号: ① brainstorming, ①½ grill, ② plans, ③ implementation
- Hook 输出 JSON 必须包含 hookEventName
- PowerShell 脚本使用 `.ps1` 扩展名, bash 使用 `.sh`

## devops

### Merge semantics
安装脚本检测已有配置、增量追加而非覆盖的行为。

### Idempotent
重复运行安装脚本产生相同结果，不会破坏已有配置。
