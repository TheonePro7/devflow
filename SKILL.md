---
name: devflow
description: devflow 5-phase product orchestrator (Ideate → Design → Setup → Develop → Finish). From raw idea to shipped product — wraps superpowers pipeline with beads + gitnexus + autoresearch + screenshot-to-code. Phase 0 (Ideate) and Phase 0.5 (Design) guide users without tech background; Phase 1-3 handle engineering.
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
4. 继续：按正常 devflow 流程执行（读取 state → 进入 Phase 0）
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
  4. 如果用户提出新想法但 state 显示 phase=0 → 必须走 Phase 0 引导
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
3. **Phase 0 (Ideate) comes first.** No design or coding before the idea is clarified. Phase 0 produces a PRD draft. Phase 0.5 (Design) follows — frontend architecture + UI generation before any backend code.
4. **Phase 0/0.5 are Claude-guided, not HITL gates.** The user provides vision and feedback; Claude structures and drives the process. Hard gates (grill, autoresearch) apply from Phase 2 onward.
5. **Autoresearch runs automatically at 3 pipeline gates (probe → scenario → fix+security).** It is ON by default. To disable: `$env:DEVFLOW_NO_AUTORESEARCH=1` (Windows) or `export DEVFLOW_NO_AUTORESEARCH=1` (Unix) before session start.
6. **No code without spec sign-off.** Phase 2 respects superpowers' hard gate: brainstorming → grill → probe → plans → scenario → implementation+TDD → fix → review → security.
7. **Git guardrails are always active.** Dangerous git commands are blocked by PreToolUse hook.
8. **ALL tools are auto-installed.** Never ask the user to install anything. If a tool is missing, install it. See [Auto-Install Rules](#auto-install-rules) below.

## Architecture

```
                     devflow (orchestrator)
                            │
       ┌────────────────────┼────────────────────┐
       ▼                    ▼                    ▼
   Phase 0             Phase 0.5           Phase 1-3
   Ideate              Design              Setup→Develop→Finish

   Idea → PRD          PRD → Frontend      Full-stack dev
       
   Claude-guided       screenshot-to-code  superpowers pipeline
   prompting           + dyad              + autoresearch gates
   + user personas     + UI architecture   + git guardrails
```

### The 5 Phases

```
Phase 0: Ideate (session-level, per-feature)
  ────────────────────────────────────────
  Goal: Turn a raw idea into a structured product brief.
  
  1. User shares raw idea/vision
  2. Claude guides structured exploration:
     - What problem are we solving?
     - Who are the target users?
     - What existing solutions exist?
     - How do we measure success?
  3. Generate product brief:
     - Product vision statement
     - User personas (2-3)
     - Feature hypotheses (MoSCoW: Must/Should/Could/Won't)
     - Risk & constraint analysis
  4. Output: PRD draft saved to docs/prd/
  
  No external tools needed — everything happens through
  Claude-guided conversation. Phase 0 ends with a PRD
  that feeds into Phase 0.5 and Phase 2.

Phase 0.5: Design (session-level, per-feature)
  ────────────────────────────────────────────
  Goal: From PRD → production-grade frontend code.
  Powered by Auto-Designer engine.

  ┌──────────────────────────────────────────────┐
  │  AUTO-DESIGNER                               │
  │                                              │
  │  1. Requirements Analysis (Claude-driven)    │
  │     ├── Classify: landing/admin/social/...    │
  │     ├── Match framework + design system       │
  │     └── Score complexity (1-5 small, 6-15    │
  │         medium, 16+ large)                   │
  │                                              │
  │  2. Complexity Router                        │
  │     ├── Small  → Claude Direct (built-in)    │
  │     ├── Medium → OpenUI (on-demand)          │
  │     ├── Large  → bolt.diy (on-demand)        │
  │     └── Screenshots → screenshot-to-code     │
  │                                              │
  │  3. Unified Post-Processor                   │
  │     ├── Inject design tokens                 │
  │     ├── Normalize project structure          │
  │     └── Create beads dev tasks               │
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

Phase 1: Setup (project-level, one-time, FULLY AUTOMATIC)
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
  This is NON-FATAL — Phase 1 continues in degraded mode.
  autoresearch is unaffected.

  Skip autoresearch install: run setup.ps1 with --skip-autoresearch
  or set DEVFLOW_NO_AUTORESEARCH=1 before setup.

Phase 2: Develop (session-level, each task)
  ─────────────────────────────────────────
  Delegates to superpowers pipeline, injects tools AND autoresearch:

  superpowers pipe         devflow injects
  ────────────────         ──────────────
  brainstorming  ──────①── beads: create epic issue
                                 gitnexus: context for design
                                 CONTEXT.md: domain vocab
  ══ GRILL ══════════════①½── challenge plan with CONTEXT.md
                                 + ADR + gitnexus (HITL gate)
  ══ AUTORESEARCH ═══════①¾── probe: adversarial constraint
                                 discovery after manual grill
                                 (/autoresearch:probe)
  writing-plans  ──────②── beads: create sub-issues per task
                                 gitnexus: impact analysis
                                 PRD→beads: auto-split tasks
  ══ AUTORESEARCH ═══════②½── scenario: edge case discovery
                                 per task before coding
                                 (/autoresearch:scenario)
  subagent-dev   ──────③── gitnexus context fed to subagents
                                 beads: bd ready check
                                 TDD deep docs
                                 ══ per-task quality gate ══
                                 each task done → :fix
                                 (/autoresearch:fix)
  code-review           (superpowers native)
  ══ AUTORESEARCH ═══════②¾── security: audit changes before
                                 finish (/autoresearch:security)
  finish-branch         (superpowers native)

  Background:    Git guardrails block dangerous commands

Phase 3: Finish (project-level, per-session)
  ─────────────────────────────────────────
  beads close all session issues
  Report session summary
```

## State File — `.devflow/state`

**每次状态变化必须更新此文件。** 字段说明：

| 字段 | 说明 | 取值示例 |
|------|------|---------|
| `phase` | 当前大阶段 | 0, 0.5, 1, 2, 3 |
| `step` | 当前精确步骤 | brainstorming, grill, probe, plans, scenario, impl, review, security |
| `feature` | 当前正在开发的功能 | "用户注册" |
| `prd` | PRD 文件路径 | "docs/prd/user-registration.md" |
| `blocker` | 阻塞原因（如有） | "等待设计稿" |
| `updatedAt` | 最后更新时间 | "2026-05-05T12:00:00Z" |

**更新规则：** 完成后一步立即更新，使用 `bd update` 写入或直接编辑文件。

**读取规则：** 收到用户消息后先读此文件，判断当前阶段再执行。如果 phase=0 且用户提新想法，走 Phase 0 引导流程。

**Hook 强制执行：**
- UserPromptSubmit：每步读取 state 注入提醒
- PreToolUse (Edit|Write)：编辑代码前检查阶段合法性
- 两个 Hook 都是自动触发，agent 无法绕过
	
## Auto-Install Rules

**Rule: If a tool is missing → install it. Never ask the user.**

### Phase 1 Tools (auto-install)

When devflow detects Phase 1 is pending, follow this sequence:

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

After all CLI tools are confirmed `command -v` passes, run the Phase 1 setup:

- **Windows**: Run `.\setup.ps1` from project root
- **Unix/macOS**: Run `bash setup.sh` from project root

The setup script handles: `bd init`, `gitnexus analyze`, seeding docs, installing autoresearch, and setting up guardrails.

### 3. Handle Failures

- `gitnexus analyze` may SIGSEGV on Windows (Node 22 / tree-sitter bug). This is NON-FATAL — Phase 1 continues in "degraded" mode.
- If `go install` fails (Go not installed): ask user to install Go first, then retry
- If `npm install -g` fails: try with `npx gitnexus` as fallback
- Report all failures clearly and stop — do NOT silently proceed with missing tools

### Phase 0.5 Tools (on-demand)

These are NOT auto-installed during setup. Install only when the user explicitly needs them:

| Tool | When to install | Install command | Check with |
|------|----------------|----------------|------------|
| **screenshot-to-code** | User has reference screenshots, mockups, or Figma designs they want to convert to frontend code | ```git clone https://github.com/abi/screenshot-to-code.git && cd screenshot-to-code && pip install -r requirements.txt && cd frontend && npm install``` | Check if `screenshot-to-code` directory exists and backend responds |

Install only on explicit user request (e.g., "use screenshot-to-code to turn this design into code").
screenshot-to-code is Python-based and requires a separate terminal/server process.

## Tool Injection Details

### ⓪ — Phase 0 Ideate Injection

When user shares a raw idea, guide them through structured exploration:

```yaml
Process:
  1. Listen to the user's idea — do NOT jump to solutions
  2. Ask clarifying questions:
     - "Who is this for?" (target users)
     - "What problem does it solve?" (pain point)
     - "How is it solved today?" (existing alternatives)
     - "What does success look like?" (KPIs)
  3. Synthesize into product brief:
     - Product vision (1-2 sentences)
     - User personas (2-3 archetypes)
     - Feature hypotheses (MoSCoW priority)
     - Risks & constraints
  4. Save PRD to docs/prd/<feature-slug>.md
  5. Confirm with user before proceeding to Phase 0.5 or Phase 1

Note: This is Claude-guided collaboration — no HITL gate needed.
      The user can always redirect. End with a clear "ready to design?"
```

### ⓪½ — Phase 0.5 Design Injection

After PRD is ready, before any backend code, generate frontend design:

```yaml
Process:
  1. From PRD → extract UI requirements:
     - Pages/screens needed
     - Key user flows & interactions
     - Data display requirements
  2. Make tech stack decisions:
     - Recommend based on project context (React for SPAs, etc.)
     - Default: HTML + Tailwind CSS (lowest barrier)
  3. Generate frontend architecture:
     - Component tree
     - Page layout blueprint
     - State management pattern
     - API integration points
  4. Generate frontend code (choose strategy):
     - User has screenshots → offer screenshot-to-code installation
     - User has no designs → Claude generates directly
     - User wants prompt-to-UI → offer dyad (npx dyad)
  5. Output:
     - Frontend scaffold (components, pages, styles)
     - API integration stubs linked to backend spec
     - docs/ux/<feature-slug>/ with design decisions

Default: Claude generates the frontend directly using the chosen
         tech stack. screenshot-to-code is for screenshot/Figma
         conversion only.
```

### ① — Brainstorming Injection

Before `superpowers-brainstorming` runs:

```yaml
beads:
  - bd create --title="<feature>" --type=epic

gitnexus:
  - gitnexus context <key-symbol> (if applicable)

context:
  - Load docs/CONTEXT.md for domain vocabulary
  - Load docs/adr/ for past architectural decisions
```

### ①½ — Plan-Grill Injection (HITL Gate)

After brainstorming, before writing plans:

> Inspired by mattpocock/skills — grill-with-docs

```yaml
Process:
  1. Load CONTEXT.md — verify all terms are defined
  2. Load relevant ADRs — check for conflicts
  3. gitnexus context — verify code-level facts
  4. beads dep check — ensure no blocked dependency
  5. Invent boundary cases the design doesn't address
  6. Output grill report to docs/superpowers/specs/

Note: This is a HUMAN-IN-THE-LOOP step. Must get confirmation.
```

### ①¾ — Autoresearch Probe Injection ★ AUTO

After grill passes, before writing plans (runs automatically unless opt-out):

> Invokes: `/autoresearch:probe`
> Duration: ~2 minutes, 8 adversarial personas interrogate the design

```yaml
When: DEVFLOW_NO_AUTORESEARCH is NOT set
What: /autoresearch:probe --chain plan,autoresearch
  Topic: <feature title from brainstorming>

Why: The manual grill finds obvious blind spots.
     autoresearch:probe goes deeper — 8 adversarial personas
     surface hidden constraints, contradictions, and assumptions
     the human missed.

Output:
  - probe/{date}-{slug}/ with spec, constraints TSV,
    contradictions, assumptions, handoff.json
  - These feed directly into writing-plans task decomposition

Opt-out: Tell the agent "skip autoresearch" or set env var
         DEVFLOW_NO_AUTORESEARCH=1 before session.
```

### ② — Writing Plans Injection

After plan is decomposed into tasks:

```yaml
beads:
  - bd create --title="<task>" --parent=<epic_id> --type=task
  - bd dep add <task> <dependency>

gitnexus:
  - gitnexus impact <symbol> --depth 2

auto-split (PRD→beads):
  - scripts/prd-to-beads.ps1/.sh -d <design.md> -e "<title>" -i <epic_id>
```

### ②½ — Autoresearch Scenario Injection ★ AUTO

After tasks are decomposed, before implementation starts:

> Invokes: `/autoresearch:scenario`
> Focus: generate edge cases for each identified task

```yaml
When: DEVFLOW_NO_AUTORESEARCH is NOT set
What: /autoresearch:scenario
  Scenario: <task title>
  Iterations: 15
  Focus: edge-cases

Why: Tasks from writing-plans describe WHAT to build.
     autoresearch:scenario generates boundary conditions,
     error states, and edge cases for each task so subagent
     implementers handle them upfront.

Output: scenario/{date}-{slug}/ with detailed test scenarios
        per task. These are added to task descriptions or
        TDD test cases before implementation begins.
```

### ③ — Implementation Injection

During `superpowers-subagent-driven-development`:

```yaml
gitnexus:
  - Pre-fetch context, feed to implementer/spec-reviewer/quality-reviewer
  - Subagents do NOT run gitnexus themselves

beads:
  - bd ready (check blocking tasks)
  - bd update <id> --claim (atomic assignment)

tdd-deep-docs:
  - Reference docs/tdd/*.md for testing philosophy

autoresearch:fix — Per-Task Quality Gate ★ AUTO:
  After EACH task implementation completes, before next task:
  Invoke: /autoresearch:fix --target "npm run build && npm test"
  If :fix finds errors → fix them → re-run → pass gate
  Only then claim next task

  This is a ZERO-ERROR GATE. Each task must pass before
  the next one starts. (Skip with "skip fix gate")
```

### ②¾ — Autoresearch Security Injection ★ AUTO

After code review, before finish-branch:

> Invokes: `/autoresearch:security --diff`

```yaml
When: DEVFLOW_NO_AUTORESEARCH is NOT set
What: /autoresearch:security --diff
  Iterations: 10

Why: Last line of defense. Audits only the changed files
     (--diff mode), applies STRIDE + OWASP Top 10 + red-team
     analysis with 4 hostile personas.

Output: security/{date}-{slug}/ with structured report.
        Critical/High findings must be resolved before finish.

Opt-out: Tell agent "skip security audit" or use env var.
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
│   ├── prd/              # Phase 0: Product Requirements Documents
│   └── ux/               # Phase 0.5: Design decisions & UI specs
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
- **Python 3.7+** (optional, only for screenshot-to-code in Phase 0.5)

Everything else — beads (bd), gitnexus, superpowers skills, autoresearch — is **auto-installed** by devflow during Phase 1. No manual npm install -g or go install needed.

## Setup for New Project

```bash
# No manual setup needed. Just open the project in Claude Code.
# SessionStart hook detects Phase 1 → agent auto-installs everything.
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
| A brand new idea (Phase 0 entry) | **Start from Phase 0.** Guide idea exploration → PRD → Phase 0.5 (design) → Phase 1-3 pipeline. Do NOT skip to brainstorming. |
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
    ── user: "new idea" ──→ ⓪ Phase 0 (explore idea)
                                │
                                └── ⓪½ Phase 0.5 (design frontend if needed)
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
