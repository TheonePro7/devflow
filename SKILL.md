---
name: devflow
description: devflow 5-phase product orchestrator (Phase 1 Ideate → Phase 2 Design → Phase 3 Setup → Phase 4 Develop → Phase 5 Finish). From raw idea to shipped product — wraps superpowers pipeline with beads + gitnexus + autoresearch + screenshot-to-code. Phase 1 (Ideate) and Phase 2 (Design) guide users without tech background; Phase 3-5 handle engineering.
---

# devflow — Development Orchestrator

## ⚠️ NEW PROJECT DETECTION — 最高优先级

**如果 `.devflow/state` 不存在，说明项目尚未初始化。** 这是判断新项目的唯一标准。

检测到新项目时，必须按以下顺序执行：

```
1. 检测：读取 .devflow/state — 文件不存在 → 新项目
2. 安装：bash setup.sh（自动安装工具 + 创建 hooks + 初始化 state）
   - Windows: bash ~/.claude/skills/devflow/setup.sh
   - 注意：⚠️ 不要问用户"要不要初始化" — 直接执行
3. 验证：确认 .devflow/state 已创建且 hooks 已注册
4. 继续：按正常 devflow 流程执行（读取 state → 进入 Phase 1）
```

**为什么这是最高优先级：**
- 三层强制机制（CLAUDE.md 最高指示 + hooks 拦截 + state 追踪）全部依赖 `setup.sh` 创建
- 不初始化 → 没有 CLAUDE.md → 没有 hooks → 没有 state → agent 必然跳步骤
- 这是 devflow 在新项目上落地的唯一入口，不可跳过

**注意：** 即使项目已经有 `.claude/settings.json` 或 `.beads/`，只要没有 `.devflow/state`，仍然算未初始化完毕。必须跑完 setup 完整流程。

## CRITICAL — State-Driven Execution (MANDATORY)

**devflow 使用 `.devflow/state` 文件驱动流程，所有 agent 必须遵守以下规则：**

```
每次收到用户消息时:
  1. 读取 .devflow/state — 了解当前阶段和步骤
  2. 按 state 执行下一步，禁止跳步骤
  3. 每完成一步 → 更新 state
  4. 如果用户提出新想法但 state 显示 phase=1 → 必须走 Phase 1 引导
```

**三层强制执行机制（不可绕过）:**
- **CLAUDE.md 最高指示** — 每次会话自动加载
- **UserPromptSubmit Hook** — 每步提醒当前状态（agent 无法忽略）
- **PreToolUse Hook (Edit|Write)** — 写代码前检查阶段，跳过步骤会告警

**CLAUDE.md** 文件（每次 session 自动加载）和 **Hook 脚本**（每步触发）共同构成记忆闭环。
Agent 没有自觉意识，但有记忆——这套机制确保 agent 永远不会"忘记"devflow 流程。

## Critical Rules

1. **devflow does not reimplement superpowers phases.** Brainstorming, writing plans, git worktrees, subagent-driven-development, code review, and branch finishing are all delegated to `superpowers-*` skills.
2. **devflow's value is tool injection** — beads task tracking, gitnexus code graph context, grill session, PRD→beads auto-split, TDD deep docs, autoresearch auto-optimization, and **screenshot-to-code frontend generation** are injected at defined points.
3. **Phase 1 (Ideate) comes first.** No design or coding before the idea is clarified. Phase 1 runs a 4-stage adaptive discovery, then invokes to-prd to produce the final PRD. Phase 2 (Design) follows — frontend architecture + UI generation before any backend code.
4. **Phase 1/2 are Claude-guided, not HITL gates.** The user provides vision and feedback; Claude drives the 4-stage discovery and invokes to-prd for formatting. Hard gates (grill, autoresearch) apply from Phase 4 onward.
5. **Autoresearch runs at 2 pipeline points (probe → security).** ON by default. Optimize loop is interactive (user decides). Disable: `$env:DEVFLOW_NO_AUTORESEARCH=1` (Windows) or `export DEVFLOW_NO_AUTORESEARCH=1` (Unix).
6. **Phase 4 follows superpowers skill chain exactly.** brainstorming (HARD GATE: design approval required) → using-git-worktrees → writing-plans → subagent-driven-development (with per-task spec-review + quality-review + code-review) → finishing-a-development-branch. devflow does NOT reimplement or restructure this chain.
7. **verification-before-completion universal gate.** No claim of completion without fresh verification evidence. Applies to every step.

## Architecture

```
                     devflow (orchestrator)
                            │
       ┌────────────────────┼────────────────────┐
       ▼                    ▼                    ▼
   Phase 1             Phase 2             Phase 3-5
   Ideate              Design              Setup→Develop→Finish

   Idea → PRD          PRD → Frontend      Full-stack dev
       
   Claude-guided       4-stage UI Design    superpowers pipeline
   prompting           Engine              + autoresearch gates
   + user personas     + framework match   + git guardrails
   + to-prd output     + Claude Direct
```

### The 5 Phases

```
Phase 1: Ideate (session-level, per-feature)
  ────────────────────────────────────────
  Goal: Raw idea → structured PRD via adaptive discovery.
  Powered by 4-stage exploration engine + to-prd for output.

  ┌──────────────────────────────────────────────┐
  │  STRUCTURED DISCOVERY ENGINE                 │
  │                                              │
  │  Stage 1: Problem Discovery                  │
  │    ├── Pain point → current state → timing   │
  │    ├── Competitive landscape                  │
  │    └── Output: Problem Statement             │
  │                                              │
  │  Stage 2: Users & Scenarios                  │
  │    ├── Persona derivation (2-3 roles)        │
  │    ├── Scenario mapping                      │
  │    └── Output: Personas + User Stories       │
  │                                              │
  │  Stage 3: Feature Discovery                  │
  │    ├── Divergent: brainstorm all features    │
  │    ├── Convergent: MoSCoW priority sort      │
  │    └── Output: Prioritized feature list      │
  │                                              │
  │  Stage 4: Constraints & Success              │
  │    ├── Technical/business/platform/ timeline │
  │    ├── Success metrics (qual + quant)        │
  │    └── Risk assessment                       │
  │                                              │
  │  KEY: Adaptive — skip stages user already    │
  │  covered. Only probe gaps.                   │
  └──────────────────────┬───────────────────────┘
                         │ structured context
                         ▼
  ┌──────────────────────────────────────────────┐
  │  to-prd skill                                │
  │  ├── Writes formatted PRD to GitHub Issues   │
  │  └── Also saves to docs/prd/<feature>.md     │
  └──────────────────────────────────────────────┘

  Phase 1 outputs structured JSON to .devflow/prd-context.json,
  then invokes to-prd for formatting. End result is a production-
  ready PRD that feeds into Phase 2 (Design) and Phase 4.

  **HANDOFF: After PRD is done, immediately proceed to Phase 2
  (UI Design Engine below). Update state: phase=2, step=ui-req.
  Do NOT skip to Phase 4.**

  **IMPORTANT: After Phase 1 completes — MUST proceed to Phase 2.
  Do NOT skip directly to Phase 4. Phase 2 is mandatory.**

Phase 2: Design (session-level, per-feature)
  ────────────────────────────────────────────
  Goal: From PRD → production-grade frontend code.
  Powered by 4-stage UI Design Engine.

  ┌──────────────────────────────────────────────┐
  │  UI DESIGN ENGINE (4-stage)                  │
  │                                              │
  │  Stage 1: UI Requirements Extraction         │
  │    ├── From PRD → identify pages/screens     │
  │    ├── Extract user flows & interactions     │
  │    ├── Identify data display requirements    │
  │    ├── Auto-classify project type            │
  │    └── Output: UI Requirements Summary       │
  │                                              │
  │  Stage 2: Architecture Blueprint             │
  │    ├── Select framework + design system      │
  │    ├── Define component tree structure       │
  │    ├── Define state management pattern       │
  │    └── Define API integration points         │
  │                                              │
  │  Stage 3: Frontend Scaffold Generation       │
  │    ├── Small (1-5 pages) → Claude Direct     │
  │    ├── Medium (6-15) → offer OpenUI          │
  │    ├── Large (16+) → offer bolt.diy          │
  │    └── Screenshots → screenshot-to-code      │
  │                                              │
  │  Stage 4: Design Documentation               │
  │    ├── Save to docs/ux/<feature-slug>/       │
  │    ├── Create beads design tasks             │
  │    ├── Update prd-context.json               │
  │    └── Update .devflow/state → Phase 3/4     │
  └──────────────────────────────────────────────┘

  Framework Matching (AUTOMATIC — no user choice needed):

  | Project Type  | Default Framework              | Design System  |
  |---------------|-------------------------------|----------------|
  | landing       | Next.js + Tailwind             | Tailwind UI    |
  | admin         | React + Ant Design             | Ant Design Pro |
  | social        | Next.js + Tailwind             | shadcn/ui      |
  | ecommerce     | Next.js + Tailwind             | shadcn/ui      |
  | tool          | React + Tailwind               | shadcn/ui      |
  | content       | Next.js + Tailwind + MDX       | Tailwind UI    |
  | mobile        | React Native + NativeWind      | NativeWind     |

  On-Demand Tool Install:
  - OpenUI (22.3k⭐): `pip install openui` — when user confirms for medium projects
  - bolt.diy (19.3k⭐): `git clone + npm install` — when user confirms for large projects
  - screenshot-to-code (72.4k⭐): Docker — when user provides screenshots

  **Default behavior (80% of projects):** Claude Direct — zero install, zero dependencies.
  Agent generates the full frontend project inline using the design token templates below.

  The agent MUST NOT ask "which framework do you want?" — analyze and decide automatically.
  Only ask the user when complexity suggests an external tool might be needed.

### Design Token Templates (for Claude Direct generation)

When generating frontend code via Claude Direct, use these design tokens:

**Color Palette Derivation:**
```
From brand color or default (#1677ff):
  Primary:    brand → 50/100/200/300/400/500/600/700/800/900
  Neutral:    gray scale
  Success:    green (#52c41a)
  Warning:    orange (#faad14)
  Error:      red (#ff4d4f)
  Info:       blue (#1677ff)
```

**Spacing Scale (Tailwind-compatible):**
```
px(1) → 0.5(2) → 1(4) → 2(8) → 3(12) → 4(16) → 5(20) → 6(24) → 8(32) → 10(40) → 12(48) → 16(64)
```

**Typography:**
```
Headings: Inter / Plus Jakarta Sans (weights: 600/700)
Body:     Inter (weight: 400)
Monospace: JetBrains Mono (for code blocks)
```

**Component Patterns (per framework):**
- React + shadcn/ui: use <Card>, <Dialog>, <Table>, <Form> primitives
- React + Ant Design: use <ProTable>, <ProForm>, <ProLayout>
- Next.js: App Router, server components by default, client components only when needed

Phase 3: Setup (project-level, one-time, FULLY AUTOMATIC)
  ────────────────────────────────────────────────────────
  Auto-detect missing tools → auto-install (go install / npm -g)
  → bd init → gitnexus analyze → seed docs/
  → configure guardrails → install autoresearch

  Triggers when SessionStart hook detects .beads/ or .gitnexus/ missing.
  Every missing tool is auto-installed by the agent or setup script.
  No manual intervention needed — zero configuration.

  Creates:
  - docs/CONTEXT.md    (domain vocabulary template)
  - docs/adr/          (architecture decision records)
  - docs/tdd/          (TDD deep reference docs)
  - .claude/hooks/guardrails-git.ps1
  - autoresearch skill (npx skills add uditgoenka/autoresearch)

  Note: gitnexus analyze may fail on Windows/bash (known SIGSEGV).
  The setup script auto-detects Docker and uses it to bypass this issue.
  See scripts/gitnexus-docker.ps1/.sh for manual Docker usage. If
  Docker is unavailable, Phase 3 continues in degraded mode.
  autoresearch is unaffected.

  Skip autoresearch install: run setup.ps1 with --skip-autoresearch
  or set DEVFLOW_NO_AUTORESEARCH=1 before setup.

Phase 4: Develop (session-level, each task)
  ─────────────────────────────────────────
  完全对齐 superpowers 原始技能链，devflow 只在定义点注入工具。

  superpowers 原始链               devflow 注入
  ────────────────────────         ──────────────
  ① brainstorming HARD GATE        beads: create epic issue
    设计→用户审批→设计文档            gitnexus-docker: context <核心符号>
    └─ 用户批准前不得写代码            CONTEXT.md: domain vocab
    ② using-git-worktrees          自动创建隔离工作区
    └─ 确保不污染主工作区
  ══ AUTORESEARCH ═══════①½── probe: 对抗人格约束发现
                                  (HARD GATE — hook拦截)
  ③ writing-plans                  beads: create sub-issues + dep link
    └─ 模板header + 无占位符规则      gitnexus-docker: impact --depth 2
    └─ 输出: 可执行计划               PRD→beads: auto-split
  ④ subagent-driven-development    gitnexus: context fed to subagents
    ├─ implementer 子 agent         beads: bd ready + bd update --claim
    ├─ spec-reviewer 子 agent       TDD deep docs (docs/tdd/)
    ├─ code-quality-reviewer        (取代 devflow 旧的 fix 门禁)
    └─ requesting-code-review       (devflow 之前标注"不参与" — 现在参与)
  ══ AUTORESEARCH ═══════②¾── security: --diff 安全审计
                                  (HARD GATE — hook拦截)
  ══ AUTORESEARCH ═══════③¼── optimize: 完整优化循环
                                  (交互式 — 用户决定)
  ⑤ finishing-a-development-branch (superpowers原生)
    └─ 4选项: merge/PR/keep/discard
    └─ cleanup: using-git-worktrees 清理

  **PHASE 4→5 HANDOFF: After finish-branch, update
  .devflow/state: phase=5, step=finish. Then proceed to Phase 5 below.**

  Background:    Git guardrails block dangerous commands

  **verification-before-completion 通用门禁:**
  任何时候声称"完成""通过""修复了"之前，必须先跑验证命令看输出。
  "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE"

  **gitnexus注:** 所有 gitnexus 命令依赖 Docker Desktop。
  每个注入点先检查 `docker ps`，不可用时推荐安装；
  用户拒绝 → 跳过 gitnexus（非致命，agent 照常工作）。

  **beads 深度使用:**
  - 依赖图: bd link <task> <dependency>
  - 标签: bd label add <id> <type>
  - 质量: bd lint + bd stale + bd orphans (Phase 5)
  - Dolt 版本: bd dolt log 追溯 issue 变更历史

Phase 5: Finish (project-level, per-session)
  ─────────────────────────────────────────
  Phase 4's optimize step already handles autoresearch.
  Phase 5 is lightweight — close and push only:
  ① Update .devflow/state: phase=5, step=finish → done
  ② beads close all session issues
  ③ git add + git commit + git push
  ④ Report session summary
```

## State File — `.devflow/state`

**每次状态变化必须更新此文件。** 字段说明：

| 字段 | 说明 | 取值示例 |
|------|------|---------|
| `phase` | 当前大阶段 | 1, 2, 3, 4, 5 |
| `step` | 当前精确步骤 | 见下方各 Phase 步骤列表 |
| `feature` | 当前正在开发的功能 | "用户注册" |
| `prd` | PRD 文件路径 | "docs/prd/user-registration.md" |
| `blocker` | 阻塞原因（如有） | "等待设计稿" |
| `gate_probe` | probe 门禁状态 | pending, done, skipped |
| `gate_security` | security 门禁状态 | pending, done, skipped |
| `updatedAt` | 最后更新时间 | "2026-05-05T12:00:00Z" |
| | **Phase 1 steps:** `problem` → `users` → `features` → `constraints` → `prd` |
| | **Phase 2 steps:** `ui-req` → `arch-decision` → `scaffold` → `ux-docs` → `design-done` |
| | **Phase 3 steps:** `setup` (single step — fully automatic) |
| | **Phase 4 steps:** `brainstorming` (HARD GATE) → `probe` → `plans` → `impl` → `security` → `optimize` |
| | **Phase 5 steps:** `finish` → `done` (close + push) |

**更新规则：** 完成后一步立即更新，使用 `bd update` 写入或直接编辑文件。

**读取规则：** 收到用户消息后先读此文件，判断当前阶段再执行。
- phase=1（Ideate）：用户提新想法，走 Phase 1 引导流程；已有 PRD 则直接进 Phase 2
- phase=2（Design）：按 4 阶段引擎执行（ui-req → arch-decision → scaffold → ux-docs → design-done）
- phase=3（Setup）：检测工具是否齐全，运行安装流程
- phase=4（Develop）：按 superpowers 原始链执行（brainstorming → probe → plans → impl → security → optimize）
- phase=5（Finish）：更新 state → close beads → git push → 报告摘要

**写入规则：** 每次状态变化后（包括 step 变更、gate 状态变化）立即更新 `.devflow/state`。agent 必须手动编辑该文件更新字段。

**Hook 强制执行：**
- UserPromptSubmit：每步读取 state 注入提醒
- PreToolUse (Edit|Write)：编辑代码前检查阶段合法性
- 两个 Hook 都是自动触发，agent 无法绕过
	
## Auto-Install Rules

**Rule: If a tool is missing → install it. Never ask the user.**

### Phase 3 Tools (auto-install)

When devflow detects Phase 3 is pending, follow this sequence:

### 1. Install CLI Tools (if missing)

Check each tool with `command -v <name>`. If missing, install:

| Tool | Install command | Check with |
|------|----------------|------------|
| **beads (bd)** | `go install github.com/gastownhall/beads/cmd/bd@latest` | `command -v bd` |
| **gitnexus** | `npm install -g gitnexus` | `command -v gitnexus` |
| **superpowers** | In Claude Code: ask user to type `/plugin install superpowers@claude-plugins-official` once (this is a Claude Code built-in, can't auto-run) | Check if `superpowers-*` skills exist |
| **autoresearch** | `npx skills add uditgoenka/autoresearch` | `command -v skills` and check if autoresearch skill directory exists |

**Order**: Install beads first, then gitnexus, then run setup script (which handles autoresearch).

### 2. Run Setup Script

After all CLI tools are confirmed `command -v` passes, run the Phase 3 setup:

- **Windows**: Run `.\setup.ps1` from project root
- **Unix/macOS**: Run `bash setup.sh` from project root

The setup script handles: `bd init`, `gitnexus analyze`, seeding docs, installing autoresearch, and setting up guardrails.

### 3. Handle Failures

- `gitnexus analyze` may SIGSEGV on Windows (Node 22 / tree-sitter bug). This is NON-FATAL — Phase 3 continues in "degraded" mode.
- If `go install` fails (Go not installed): ask user to install Go first, then retry
- If `npm install -g` fails: try with `npx gitnexus` as fallback
- Report all failures clearly and stop — do NOT silently proceed with missing tools

### Phase 2 Tools (on-demand)

These are NOT auto-installed during setup. Install only when the user explicitly needs them:

| Tool | When to install | Install command | Check with |
|------|----------------|----------------|------------|
| **screenshot-to-code** | User has reference screenshots, mockups, or Figma designs they want to convert to frontend code | ```git clone https://github.com/abi/screenshot-to-code.git && cd screenshot-to-code && pip install -r requirements.txt && cd frontend && npm install``` | Check if `screenshot-to-code` directory exists and backend responds |

Install only on explicit user request (e.g., "use screenshot-to-code to turn this design into code").
screenshot-to-code is Python-based and requires a separate terminal/server process.

## Tool Injection Details

### ⓪ — Phase 1 Ideate Injection

**Golden rule: Listen first — do NOT jump to solutions.**
Your job is to explore the problem, not design the product.
Let the user finish sharing their idea before asking questions.

When user shares a raw idea, run the 4-stage adaptive discovery engine.
Each stage auto-detects if the user has already covered that dimension.
Only probe gaps. Never ask mechanical questions.

**Important references before starting:**
- Load docs/CONTEXT.md for domain vocabulary (if exists)
- Check docs/adr/ for relevant past decisions
- Create docs/prd/ directory if it doesn't exist

```yaml
Process Overview:
  Adaptive 4-stage discovery → structured JSON → to-prd output

  Stage 1: Problem Discovery
    Goal: Validate that this problem is worth solving.
    Triggers (auto-detect, only ask if missing):
      - Pain point: "What specific problem are we solving? Who feels it?"
      - Current state: "How is this handled today?"
      - Timing: "Why now? What changed?"
      - Competition: "Are there existing solutions? What's missing?"
    Output: Problem Statement (1-2 paragraphs)
    Skip: If user already described all four dimensions → just confirm
    Edge case: User vague → ask "Let me make sure I understand the problem..."
    Edge case: User has strong opinions on implementation → "Let's park the 
               implementation details for now. First I want to understand..."

  Stage 2: Users & Scenarios
    Goal: Identify who this is for and what they need.
    Process:
      1. Derive 2-3 persona archetypes from context (identity → need → pain)
      2. Show to user: "Does this sound right?"
      3. For each persona, generate 3-5 User Stories
    User Story format (from to-prd):
      As a <role>, I want <capability>, so that <benefit>
    Example:
      As a small shop owner, I want one-click product poster generation,
      so that I can promote on social media without hiring a designer
    Output: 2-3 Personas + 6-15 User Stories
    Skip: If user already named target users → refine, don't re-ask
    Edge case: User says "everyone" → help segment: "Who needs this most?"

  Stage 3: Feature Discovery
    Goal: From divergent brainstorm to prioritized scope.
    Phase A — Divergent:
      1. Ask: "What features do you envision for this?"
      2. If user runs dry, suggest based on domain knowledge + competitors
    Phase B — Convergent (MoSCoW):
      - Must: core path, unusable without
      - Should: important but has workaround
      - Could: nice-to-have, only with extra resource
      - Won't: explicitly defer to future
    Deep Module check (from to-prd):
      After listing features, look for one that encapsulates complexity
      behind a simple interface — that's a deep module candidate.
      Flag it: "I notice <feature> could be a deep module..."
    Output: MoSCoW-sorted feature list, each Must/Should mapped to User Stories
    Skip: If user has a clear feature list → go straight to MoSCoW sorting

  Stage 4: Constraints & Success
    Goal: Ensure the PRD is feasible and testable.
    Scan systematically for gaps (only ask what's missing):
      - Tech stack: Languages, frameworks, hosting?
      - Timeline: When should this ship?
      - Platform: Web / iOS / Android / all?
      - Business: Compliance, security, auth model?
      - Success (qual): What does "using it" look like?
      - Success (quant): DAU, conversion rate, response time, coverage?
      - Risks: Top 3 risks and mitigations?
    ADR check: Scan docs/adr/ for decisions affecting this feature
    Output: Constraints + Success Metrics + Risk matrix

  Handoff — to-prd integration:
    After all 4 stages complete:
    1. Collect all outputs into structured JSON
    2. Save to .devflow/prd-context.json:
       {
         "phase": 1,
         "stage": "complete",
         "outputs": {
           "problemStatement": "<from Stage 1>",
           "personas": [{"name":"...", "needs":"...", "painPoints":"..."}],
           "userStories": ["As a ..., I want ..., so that ..."],
           "featurePriority": {"must":["..."], "should":["..."], "could":["..."], "wont":["..."]},
           "constraints": {"tech":"...", "timeline":"...", "platform":"...", "business":"..."},
           "successMetrics": {"qualitative":"...", "quantitative":"..."},
           "risks": [{"risk":"...", "mitigation":"..."}]
         }
       }
    3. Confirm with user: "Ready to turn this into a formal PRD?"
    4. Run: /to-prd (let to-prd format and publish)
    5. Also save final PRD to docs/prd/<feature-slug>.md

Edge Cases:
  - User already has a full PRD: Skip Stages 1-3. Stage 4 validates
    completeness, then directly hand off to to-prd.
  - User changes mind mid-stream: Restart from Stage 1, but preserve
    confirmed info. Don't re-ask settled questions.
  - User is in a hurry: "Quick mode" — one question per stage,
    only the most critical gap.
  - No CONTEXT.md exists: Create it during Stage 2 with domain terms.

Note: This is Claude-guided collaboration — no HITL gate needed.
      The user can always redirect. End each stage with confirmation.
      End the full discovery with "Ready to turn this into a PRD?"
```

### Phase 2 Design Injection **★ MANDATORY**

**After PRD is ready, MUST execute Phase 2 before proceeding to Phase 4. Do NOT skip.**

Update `.devflow/state` to phase=2 at start, then step through each stage:

```yaml
Phase 2: UI Design Engine (4-stage executable flow)
  State: phase=2, step=ui-req

  Stage 1: UI Requirements Extraction (step=ui-req)
    Goal: From PRD → structured UI requirements.
    Process:
      1. Read PRD from docs/prd/<feature>.md
      2. Extract pages/screens needed (list each with purpose)
      3. Extract key user flows & interactions (step-by-step)
      4. Extract data display requirements (tables, charts, forms, lists)
      5. Auto-classify project type:
         - landing / admin / social / ecommerce / tool / content / mobile
      6. Show user: "Here's what I understand about the UI needs..."
      7. Wait for confirmation before proceeding
    Edge case: User says "no UI needed" (CLI/API project):
      → Skip Phase 2 entirely. Set state to phase=4.
      → Create beads epic issue, proceed to Phase 4 pipeline.
    Edge case: User has screenshots/Figma:
      → Note it for Stage 3 (screenshot-to-code option)
    Output: Structured UI requirements (appended to prd-context.json)

  Stage 2: Architecture Blueprint (step=arch-decision)
    Goal: Select stack and define structure.
    Process:
      1. Select framework + design system from matching table:
         | Type       | Framework              | Design System  |
         |------------|-----------------------|----------------|
         | landing    | Next.js + Tailwind     | Tailwind UI    |
         | admin      | React + Ant Design     | Ant Design Pro |
         | social     | Next.js + Tailwind     | shadcn/ui      |
         | ecommerce  | Next.js + Tailwind     | shadcn/ui      |
         | tool       | React + Tailwind       | shadcn/ui      |
         | content    | Next.js + Tailwind+MDX | Tailwind UI    |
         | mobile     | React Native+NativeWind| NativeWind     |
         Do NOT ask user — decide automatically.
      2. Define component tree (parent → children hierarchy)
      3. Define state management: Context / Zustand / Redux / React Query
      4. Define API integration points per page
      5. Show blueprint: "Here's the architecture I propose..."
      6. Wait for confirmation
    Edge case: Existing project has a stack already:
      → Respect existing tech stack. Don't suggest a new one.
      → Only add new components, don't restructure.
    Output: Architecture blueprint → save to docs/ux/<feature>/architecture.md

  Stage 3: Frontend Scaffold Generation (step=scaffold)
    Goal: Generate frontend code from the blueprint.
    
    **HARD GATE: 必须先呈现设计给用户批准才能生成代码。**
    这是 superpowers brainstorming 的延伸 — 前端设计输出后用户必须确认。
    "太简单不需要"不是跳过理由。
    
    Process:
      1. 呈现出架构概览: "这是设计蓝图, 共 X 页/组件, 使用 <框架> + <设计系统>"
      2. **等待用户确认设计** → 获得批准后才能写代码
      3. Count pages from Stage 1 → determine complexity:
         - 1-5 pages  → Claude Direct (DEFAULT, zero install)
         - 6-15 pages → Ask user: "This has X pages, want to use OpenUI?"
         - 16+ pages  → Ask user: "Large project, want to use bolt.diy?"
         - Has screenshots → Ask: "Want to use screenshot-to-code?"
      4. Claude Direct (80% of projects):
         a. Create project directory (if not existing):
            - For new: scaffold with chosen framework
            - For existing: add to appropriate directory
         b. Generate components page by page:
            - Apply design tokens (colors, spacing, typography from templates below)
            - Follow chosen design system primitives
            - Generate responsive layouts
         c. Generate API integration stubs:
            - Match to backend spec from PRD
            - Use fetch/axios with typed interfaces
         d. Generate routes/navigation structure
      5. Apply design tokens:
         - Color palette from brand color (#1677ff default)
         - Spacing scale (Tailwind-compatible)
         - Typography (Inter / Plus Jakarta Sans)
      6. Show user the generated frontend
      7. Wait for feedback, iterate if needed
    Edge case: User wants a specific framework not in the table:
      → Use whatever the user specifies. Framework matching is a default, not a constraint.
    Output: Frontend scaffold code + API stubs

  Stage 4: Design Documentation & Handoff (step=ux-docs → design-done)
    Goal: Persist decisions and prepare for Phase 4.
    Process:
      1. Create docs/ux/<feature-slug>/ with:
         - README.md: design decisions summary
         - architecture.md: component tree, state management, API points
         - screens.md: per-page description and component mapping
      2. Update .devflow/prd-context.json:
         Add design section: { "design": { "techStack": "...",
           "componentTree": [...], "pages": [...], "apiPoints": [...] } }
      3. Create beads tasks for remaining frontend work:
         bd create --title="<feature> frontend" --type=epic
         bd create --title="Implement <component>" --parent=<epic> --type=task (per component)
      4. Update .devflow/state:
         Check if tools are installed (bd, gitnexus):
           - If NOT installed → phase=3, step=setup
           - If installed → phase=4, step=brainstorming
         This ensures Phase 3 setup is never accidentally skipped.
      5. Confirm with user: "Frontend design complete. Ready to enter the
         development pipeline."
```

Note: This is Claude-guided — no HITL gates. The user confirms each stage.
If the project is CLI-only / API-only / library (no UI), skip Phase 2 entirely.

### ① — Brainstorming + HARD GATE (superpowers 原生)

**调用: superpowers-brainstorming Skill**

这是 superpowers 原生的设计探索技能。强制执行 HARD GATE：无设计审批不得写代码。

**按 brainstorming 的 9 步清单执行:**
1. 探索项目上下文 — 文件、文档、最近提交
2. 如有需要提供视觉伴侣
3. 逐一提问澄清需求
4. 提出 2-3 种方案 + 权衡利弊 + 推荐
5. 呈现设计 — 分节展示，每节用户确认
6. 写设计文档 → `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
7. 自审查 — 无占位符、无矛盾、范围聚焦
8. 用户审查文档
9. 输出设计文档 + git commit

**devflow 注入:**
```yaml
beads:
  - bd create --title="<feature>" --type=epic

gitnexus (via Docker):
  - 先检查 docker ps（不可用→推荐安装 Docker Desktop）
  - 用户拒绝→跳过 gitnexus（非致命）
  - 可用时: .\scripts\gitnexus-docker.ps1 context <核心符号>
   或: bash scripts/gitnexus-docker.sh context <core-symbol>

context:
  - 加载 docs/CONTEXT.md
  - 加载 docs/adr/ 相关 ADR

设计审批:
  - 用户必须批准设计才能继续
  - 这是 HARD GATE — agent 不得跳过

Transition: 设计批准后 → 进入 using-git-worktrees 创建隔离工作区
```

### ①½ — Autoresearch Probe Injection ★ HARD GATE

设计批准后、writing-plans 前。**PreToolUse hook 在 step=probe 时检查 gate_probe != done 会拦截。**

> 调用: `$autoresearch probe`
> 8 个对抗人格（架构师、安全分析师、性能工程师等）独立分析设计后辩论达成共识

```yaml
Enforcement: HARD — hook blocks Edit|Write when step=probe and gate_probe=pending
What: $autoresearch probe
  Topic: <feature title>
  Depth: standard

Why: Brainstorming 找到的明显盲点由用户评审捕获。
     autoresearch:probe 深入更底层 — 发现隐藏约束、矛盾、
     和用户设计团队成员都没意识到的假设。

Output: probe/{date}-{slug}/ with spec, constraints TSV,
        contradictions, assumptions, handoff.json
        这些结果结构化输入到 writing-plans

After completion:
  Update .devflow/state → set gate_probe=done, step=plans

Opt-out: Set gate_probe=skipped in .devflow/state
```

### ② — Writing Plans (superpowers 原生) + beads 深度注入

**调用: superpowers-writing-plans Skill**

按 superpowers 格式写计划：
- 必须含有 header（标题 + Goal + Architecture + Tech Stack）
- 无占位符规则 — 每个 task 必须有实际代码、实际命令
- 自审查：spec 覆盖率、占位符扫描、类型一致性

**devflow 注入:**
```yaml
beads:
  - bd create --title="<task>" --parent=<epic_id> --type=task
  - bd link <task> <dependency>    # 设置依赖图
  - bd label add <id> <type>       # 添加类型标签

gitnexus (if Docker available):
  - .\scripts\gitnexus-docker.ps1 impact <symbol> --depth 2
  - 将影响范围注入 task 描述

auto-split (PRD→beads):
  - scripts/prd-to-beads.ps1/.sh -d <design.md> -e "<title>" -i <epic_id>

Execution handoff:
  提供两种选项给用户:
  1. subagent-driven-development (推荐 — 同一会话)
  2. executing-plans (隔离会话)
```

### ③ — Subagent-Driven Development (superpowers 原生) + 全注入

**调用: superpowers-subagent-driven-development Skill**

完整的 per-task 循环:
1. 派发 implementer 子 agent（含 gitnexus context + TDD docs）
2. 派发 spec-reviewer 子 agent（审查代码是否符合设计）
3. 派发 code-quality-reviewer 子 agent（审查代码质量）
4. 派发 requesting-code-review（审查功能完整性）
5. 完成后 → finishing-a-development-branch

**devflow 注入:**
```yaml
gitnexus (if Docker available):
  - 主 agent 预取 context 传给每个子 agent
  - 子 agent 不直接运行 gitnexus

beads (深度):
  - bd ready           # 检查阻塞依赖
  - bd update --claim  # 原子分配
  - 每个 subagent 完成后记录到 beads note
  - bd gate set <id>   # 用 beads 原生门禁跟踪进度

tdd-deep-docs:
  - 引用 docs/tdd/*.md 作为测试哲学参考

requesting-code-review:
  在每个 task 完成后、下一个 task 开始前调用。
  使用 superpowers 原生的 code-reviewer 模板:
    1. 获取 BASE_SHA / HEAD_SHA
    2. 派发 code-reviewer 子 agent
    3. 修复 Critical/Important 发现
    4. 记录 Minor 发现

verification-before-completion:
  每个 task 完成后：先跑验证命令，看输出，再声称完成。
  通用门禁 — "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE"
```

### ②¾ — Autoresearch Security Injection ★ HARD GATE

code-review 完成后、finish-branch 前。**PreToolUse hook 在 step=security 时检查 gate_security != done 会拦截。**

> 调用: `$autoresearch security --diff`
> 只审计本次变更的文件

```yaml
Enforcement: HARD — hook blocks Edit|Write when step=security and gate_security=pending
What: $autoresearch security --diff
  Iterations: 10

Why: 最后一道防线。自动安全审计——STRIDE + OWASP Top 10 + 4 个红队人格。
     --diff 模式确保只审计本次变更，不扫描全项目。

Output: security/{date}-{slug}/ with structured report.
        Critical/High 发现必须修复后才能 finish。

After completion:
  Update .devflow/state → set gate_security=done, step=optimize

Opt-out: Set gate_security=skipped in .devflow/state
```

### ③¼ — Autoresearch Optimize ★ 完整循环 (INTERACTIVE)

安全门禁通过后、finish-branch 前。**Agent 必须先问用户。这是唯一的交互式步骤。**

> 调用完整 autoresearch 循环：`/autoresearch:plan` → `/autoresearch` → keep/revert → 记录

```yaml
What: Ask the user:
  "功能已完成并通过所有门禁。是否要运行 autoresearch 自动优化循环？
  
  你可以设定一个优化目标，比如：
  - 提高测试覆盖率到 XX%
  - 优化性能（减少响应时间）
  - 减少包体积
  - 代码重构改进
  - 其他自定义目标
  
  系统会:
    1. 启动完整优化循环（修改→验证→保留/回滚→重复）
    2. 每次修改自动 git commit（experiment: 前缀）
    3. 失败的修改自动 git revert
    4. 记录每次迭代结果到 TSV 日志
    5. 完成后报告哪些改进保留、哪些回滚、净效果"

If user agrees:
  1. 引导设置: Goal + Scope + Metric + Iterations (建议 10-15)
  2. 运行: $autoresearch run --goal "<goal>" --scope "<files>" --metric "<metric>" --iterations 10
  3. 记录结果到: docs/superpowers/optimize/{date}-{slug}/
  4. 用户决定 keep 或 revert 优化结果
  5. 更新 state: phase=5, step=finish

If user declines:
  → Update .devflow/state: phase=5, step=finish
  → Proceed to Phase 5 close + push

Opt-out: User says "skip optimize"
```

### ⑤ — Finishing a Development Branch (superpowers 原生)

**调用: superpowers-finishing-a-development-branch Skill**

superpowers 原生流程:
1. 验证测试
2. 确定 base branch
3. 提供 4 选项（merge/PR/keep/discard）
4. 执行选择
5. 清理 worktree

**然后 → Phase 5 close + push**

Opt-out: User says "no" or "skip optimize"
```

### Git Guardrails (Background)

PreToolUse hook blocks dangerous git patterns:

- `git push --force` / `git push -f`
- `git reset --hard` / `git clean -fd`
- `git branch -D` / `git checkout .` / `git restore .`

Override via `.claude/settings.local.json` allow array.

## Opt-Out Mechanism

Autoresearch is ON by default at 4 pipeline points.
To disable globally:

```bash
# PowerShell (before Claude Code session):
$env:DEVFLOW_NO_AUTORESEARCH = 1

# bash (before Claude Code session):
export DEVFLOW_NO_AUTORESEARCH=1
```

To skip a single gate, tell the agent:
- "skip probe" (skips ①¾)
- "skip scenario" (skips ②½)
- "skip fix gate" (skips per-task :fix in ③)
- "skip security audit" (skips ②¾)

## Project Structure

```
devflow/
├── SKILL.md                    # Orchestrator definition
├── setup.ps1                   # Phase 1 Setup (Windows)
├── setup.sh                    # Phase 1 Setup (Unix)
├── README.md
├── LICENSE
├── .gitignore
├── .devflow/                    # State-driven execution
│   └── state                    # Current phase/step/feature
├── .claude/
│   ├── settings.json           # Project hooks
│   ├── settings.local.json     # Local overrides (gitignored)
│   └── hooks/
│       ├── devflow-init-check.ps1
│       ├── devflow-init-check.sh
│       ├── devflow-state-check.ps1  # UserPromptSubmit hook
│       ├── devflow-state-check.sh
│       ├── devflow-phase-check.ps1  # PreToolUse Edit|Write
│       ├── devflow-phase-check.sh
│       ├── guardrails-git.ps1
│       └── guardrails-git.sh
├── scripts/
│   ├── prd-to-beads.ps1
│   └── prd-to-beads.sh
├── docs/
│   ├── CONTEXT.md
│   ├── adr/
│   ├── tdd/
│   ├── prd/              # Phase 1: Product Requirements Documents
│   └── ux/               # Phase 2: Design decisions & UI specs
└── docs/superpowers/specs/
```

devflow has no prompts directory. All subagent prompts are owned by
`superpowers-subagent-driven-development`. autoresearch is a separate
skill installed via `npx skills add`.

## Prerequisites

Users need only these base dependencies (devflow auto-installs everything else):

- **Go** (for beads) — `winget install GoLang.Go 2.0` or https://go.dev/dl/
- **Node.js ≥ 18** + **npm** (for gitnexus, autoresearch)
- **Git**
- **Python 3.7+** (optional, only for screenshot-to-code in Phase 2)

Everything else — beads (bd), gitnexus, superpowers skills, autoresearch — is **auto-installed** by devflow during Phase 1. No manual npm install -g or go install needed.

## Setup for New Project

```bash
# No manual setup needed. Just open the project in Claude Code.
# SessionStart hook detects Phase 3 → agent auto-installs everything.
```

If you want to run setup manually (not recommended):
```bash
# PowerShell:
.\setup.ps1
# or bash:
# bash setup.sh
```

## Mid-Session New Task Handling

When the user proposes a new task mid-pipeline (e.g., during implementation ③), the pipeline is **not** linear-only. Handle based on scope:

### Classification

| If the request is... | Then... |
|----------------------|---------|
| A brand new idea (Phase 1 entry) | **Start from Phase 1.** Guide idea exploration → PRD → Phase 2 (design) → Phase 3-5 pipeline. Do NOT skip to brainstorming. |
| A small tweak within current scope (rename, minor UI adjust, error message) | Handle inline via current subagent — no re-entry |
| A logical sub-task missed during writing-plans (e.g., "also need a validation layer") | Create a beads sub-task, run autoresearch:fix gate on it. Do NOT restart pipeline |
| A genuinely new feature unrelated to current work | Record as beads issue, defer to next session. Do NOT interrupt current pipeline |
| An expansion that changes current design assumptions ("actually the format should be completely different") | **Pause implementation.** Re-enter pipeline at ① brainstorming with the new constraint. Grill + probe again |

### Recovery Flow (Design Expansion Only)

```
③ implementation in progress
    │
    ── user: "change direction" ──→ ① brainstorming (revised)
                                       │
                                       ├── ①½ grill (re-check)
                                       ├── ①¾ probe (re-check)
                                       ├── ② plans (revised)
                                       ├── ②½ scenario (re-generated)
                                       └── ③ implementation (continue)
                                              └── autoresearch:fix (re-run)
```

### Recovery Flow (New Idea During Session)

```
③ implementation in progress
    │
    ── user: "new idea" ──→ ⓪ Phase 1 (explore idea)
                                │
                                └── ⓪½ Phase 2 (design frontend if needed)
                                       │
                                       └── Previous work paused, new work begins
                                              Phase 1-3 for the new feature
```

**Key rule**: Do NOT silently restart the pipeline without telling the user. State the plan and confirm before abandoning in-progress work.

- Build verification is **mandatory** before commit
- Code is not done until `git push` succeeds
- Git guardrails block dangerous operations
- Grill session is required (HITL gate between brainstorming and plans)
- **Autoresearch gates run automatically — do not skip unless user says so**
- PRD→beads auto-split preferred over manual bd create
- TDD discipline enforced by superpowers-test-driven-development + docs/tdd/
- CONTEXT.md and ADRs evolve with project understanding
- 3-round max for subagent review loops; escalate to human after 3
