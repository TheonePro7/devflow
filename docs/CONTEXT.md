# Project Context — Ubiquitous Language

## Project

devflow — Claude Code 全生命周期产品编排器。5 阶段（Ideate → Design → Setup → Develop → Finish）从模糊创意到可交付产品。包含四层强制机制确保 agent 严格遵循流程。

## Domain Glossary

### Phase 1 (Ideate)
产品创意梳理阶段。4 阶段自适应探索引擎（问题发现 → 用户场景 → 功能探索 → 约束与标准），探索完成后调用 `to-prd` 技能格式化输出 PRD 到 `docs/prd/` 和 GitHub Issues。自适应机制：已覆盖内容自动跳过。

### Phase 2 (Design)
前端设计阶段。PRD → 前端脚手架。三种方式：Claude 直接生成（默认）、screenshot-to-code、dyad。

### Phase 3 (Setup)
项目级一次性初始化。beads init + gitnexus analyze + docs seed + guardrails 配置 + .devflow/state 创建。
由 setup.ps1/setup.sh 自动执行。新项目中由 SKILL.md 检测并触发。

### Phase 4 (Develop)
会话级开发循环。完全对齐 superpowers 原始链：brainstorming (HARD GATE: 设计审批) → using-git-worktrees (隔离工作区) → writing-plans (模板+自审查) → subagent-driven-development (per-task implementer + spec-review + quality-review + code-review) → autoresearch security (HARD GATE) → autoresearch optimize (交互式) → finishing-a-development-branch。devflow 在定义点注入 beads、gitnexus。

### Phase 5 (Finish)
会话级收尾。更新 state → beads close → git push → 报告摘要。优化已在 Phase 4 完成，Phase 5 只做轻量收尾。

### beads
Dolt-backed issue tracker。层级 ID (bd-xxx.y)、依赖管理、状态追踪。命令前缀: `bd`。

### gitnexus
代码知识图谱。分析仓库构建符号索引。命令: `gitnexus context` / `gitnexus impact`。
Windows 下 tree-sitter 原生模块 crash，通过 Docker 容器运行（`scripts/gitnexus-docker.ps1`）。

### Brainstorming HARD GATE
superpowers-brainstorming 强制要求：必须先呈现设计给用户批准，才能写代码。"太简单不需要"不是跳过理由。
devflow 的 Phase 4 第一步对齐此门禁。

### Autoresearch
autoresearch 是 SKILL.md（prompt 集合），不是可执行 CLI。
devflow 的 `AutoresearchAdapter` 内置实现核心逻辑：
  - `security()` — 自动扫描 shell=True 调用、敏感文件泄露等常见安全问题
  - `probe()` / `fix()` — 引导上层用子代理加载 autoresearch SKILL.md
  - `run_verification()` — 直接运行测试命令（不依赖 autoresearch）
适配器不再调用不存在的 `npx skills run` 接口。
状态追踪：`.devflow/state` 中的 `gate_probe/gate_security`（取值: pending, done, skipped）。
默认开启。关闭: `DEVFLOW_NO_AUTORESEARCH=1`。单门跳过：设置对应 gate 字段为 `skipped`。

### Git guardrails
PreToolUse (Bash) hook。拦截 7 类危险 git 命令（force push, reset --hard, clean -fd, branch -D 等）。

### Verification-before-completion
通用门禁：任何时候声称"完成""通过""修复了"之前，必须先跑验证命令看输出。
铁律：NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.

### beads 深度使用
devflow 利用 beads 的完整能力：依赖图（bd link）、门禁（bd gate）、标签（bd label）、
质量检查（bd lint/bd stale/bd orphans）、Dolt 版本历史。

### using-git-worktrees
superpowers 的隔离工作区管理。Phase 4 的 brainstorming 之后自动创建隔离分支工作区，
确保主工作区不被污染。finish-branch 后自动清理。

### State-Driven Execution (强制流程关键概念)
`.devflow/state` 文件驱动所有执行决策。Agent 收到每条消息必须先读此文件。每完成一步必须更新。字段: phase, step, feature, gate_probe, gate_security, updatedAt。
Phase 1-5 各有独立步骤列表（`problem→users→features→constraints→prd` / `ui-req→arch-decision→scaffold→ux-docs→design-done` / `setup` / `brainstorming→probe→plans→impl→security→optimize` / `finish→done`）。

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
- phase < 3 且编辑代码 → 告警"需求梳理未完成"
- phase=4 + brainstorming 中且代码编辑 → 告警"设计未批准不得写代码"
- phase=4 + step=probe 且 gate_probe != done → 拦截（必须先运行 probe）
- phase=4 + step=security 且 gate_security != done → 拦截（必须先运行 security）

### UserPromptSubmit State Reminder
用户每发一条消息，hook 读取 `.devflow/state` 注入当前状态。Agent 无法忽略此提醒。

### SIGSEGV (gitnexus)
已知问题。gitnexus 在 Windows/bash (Node 22) 下 tree-sitter 原生模块 crash，exit code 139。
解决：用 Docker 容器运行 — `scripts/gitnexus-docker.ps1` 自动处理。

## Architecture Decisions

详见 [docs/adr/](adr/)：

- 0001 — Use devflow 5-Phase Orchestration (accepted)
- 0002 — Use State-Driven Execution with Four-Layer Enforcement (accepted)
- 0003 — Devflow Engine Architecture — Python CLI 状态机引擎 (approved 2026-06-07)

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
- `.devflow/state` 已废弃（迁移到 beads 存储）。事实来源为 devflow engine + beads
- devflow engine 使用 Python 3.11+，CLI 工具 `devflow` 全局安装

## devops

### Merge semantics
安装脚本检测已有配置、增量追加而非覆盖的行为。

### Idempotent
重复运行安装脚本产生相同结果，不会破坏已有配置。
