# Project Context — Ubiquitous Language

## Project

devflow — Claude Code 全生命周期产品编排器。5 阶段（Ideate → Design → Setup → Develop → Finish）从模糊创意到可交付产品。包含四层强制机制确保 agent 严格遵循流程。

## Domain Glossary

### Phase 0 (Ideate)
产品创意梳理阶段。4 阶段自适应探索引擎（问题发现 → 用户场景 → 功能探索 → 约束与标准），探索完成后调用 `to-prd` 技能格式化输出 PRD 到 `docs/prd/` 和 GitHub Issues。自适应机制：已覆盖内容自动跳过。

### Phase 0.5 (Design)
前端设计阶段。PRD → 前端脚手架。三种方式：Claude 直接生成（默认）、screenshot-to-code、dyad。

### Phase 1 (Setup)
项目级一次性初始化。beads init + gitnexus analyze + docs seed + guardrails 配置 + .devflow/state 创建。
由 setup.ps1/setup.sh 自动执行。新项目中由 SKILL.md 检测并触发。

### Phase 2 (Develop)
会话级开发循环。委托 superpowers 14-skill 管道。devflow 在 7 个注入点加入 beads、gitnexus、grill、autoresearch。

### Phase 3 (Finish)
会话级收尾。beads close 当前会话 issues + git push。

### beads
Dolt-backed issue tracker。层级 ID (bd-xxx.y)、依赖管理、状态追踪。命令前缀: `bd`。

### gitnexus
代码知识图谱。分析仓库构建符号索引。命令: `gitnexus context` / `gitnexus impact`。

### Plan-grill
HITL 关卡。位于 brainstorming → writing-plans 之间。用 CONTEXT.md + ADR + gitnexus 拷问设计盲点。

### Autoresearch
4 个自动优化门：probe（约束发现）→ scenario（边界案例）→ fix（零错误门）→ security（安全审计）。
默认开启。关闭: `DEVFLOW_NO_AUTORESEARCH=1`。

### Git guardrails
PreToolUse (Bash) hook。拦截 7 类危险 git 命令（force push, reset --hard, clean -fd, branch -D 等）。

### State-Driven Execution (强制流程关键概念)
`.devflow/state` 文件驱动所有执行决策。Agent 收到每条消息必须先读此文件。每完成一步必须更新。字段: phase, step, feature, updatedAt。

### Supreme Directive（最高指示）
记录在项目 CLAUDE.md 顶部的系统级指令。每次 session 自动加载。5 条规则，最高优先级，覆盖所有其他指令。

### Global SessionStart Hook
注册在 `~/.claude/settings.json`，在每个 Claude Code 会话启动时触发。检测 `.devflow/state` 是否存在：
- 不存在 → 提示 devflow 初始化
- 存在 → 静默通过
新项目唯一的外部入口。

### New Project Auto-Detect
SKILL.md 顶部检测逻辑。`.devflow/state` 不存在 → agent 自动运行 setup.sh。不可询问用户。

### Four-Layer Defense（四层防御链）
- Layer 0: 全局 Hook（新项目入口）
- Layer 1: SKILL.md 新项目检测（agent 级别）
- Layer 2: CLAUDE.md 最高指示（系统级提示）
- Layer 3: 项目 Hooks（UserPromptSubmit + PreToolUse）

### PreToolUse Phase Check
Edit|Write 操作前的阶段合法性检查。拦截规则：
- phase < 1 且编辑代码 → 告警"需求梳理未完成"
- phase=2 + brainstorming 且编辑代码 → 告警"跳过关键步骤"

### UserPromptSubmit State Reminder
用户每发一条消息，hook 读取 `.devflow/state` 注入当前状态。Agent 无法忽略此提醒。

### SIGSEGV (gitnexus)
已知问题。gitnexus 在 Windows/bash (Node 22) 下 tree-sitter 原生模块 crash，exit code 139。

## Architecture Decisions

详见 [docs/adr/](adr/)：

- 0001 — Use devflow 5-Phase Orchestration (accepted)
- 0002 — Use State-Driven Execution with Four-Layer Enforcement (accepted)

## External Systems

- superpowers (obra/superpowers) — 14-skill pipeline
- beads (gastownhall/beads) — issue tracker
- gitnexus (npm) — code knowledge graph
- autoresearch (uditgoenka/autoresearch) — autonomous iteration loop
- mattpocock/skills — pattern source (grill, TDD docs, guardrails, CONTEXT.md, ADR)

## Conventions

- SKILL.md 顶部置顶 ⚠️ NEW PROJECT DETECTION 区块（高于一切其他规则）
- CLAUDE.md 顶部置顶 ⚠️ 最高指示（高于任何开发约定）
- Hook 输出 JSON 必须包含 hookEventName
- PowerShell 脚本使用 `.ps1` 扩展名, bash 使用 `.sh`
- `.devflow/state` 是单一事实来源，禁止在多个地方维护状态

## devops

### Merge semantics
安装脚本检测已有配置、增量追加而非覆盖的行为。

### Idempotent
重复运行安装脚本产生相同结果，不会破坏已有配置。
