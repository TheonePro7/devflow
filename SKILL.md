---
name: devflow
description: devflow 3-phase development orchestrator (Setup → Develop → Finish). Wraps superpowers with beads + gitnexus + autoresearch. Auto-triggers on session start — Phase 1 pending triggers setup flow, Phase 1 ready enables the full pipeline.
---

# devflow — Development Orchestrator

## Critical Rules

1. **devflow does not reimplement superpowers phases.** Brainstorming, writing plans, git worktrees, subagent-driven-development, code review, and branch finishing are all delegated to `superpowers-*` skills.
2. **devflow's value is tool injection** — beads task tracking, gitnexus code graph context, grill session, PRD→beads auto-split, TDD deep docs, and **autoresearch auto-optimization** are injected at defined points.
3. **Autoresearch runs automatically at 3 pipeline gates (probe → scenario → fix+security).** It is ON by default. To disable: `$env:DEVFLOW_NO_AUTORESEARCH=1` (Windows) or `export DEVFLOW_NO_AUTORESEARCH=1` (Unix) before session start.
4. **No code without spec sign-off.** Phase 2 respects superpowers' hard gate: brainstorming → grill → probe → plans → scenario → implementation+TDD → fix → review → security.
5. **Git guardrails are always active.** Dangerous git commands are blocked by PreToolUse hook.

## Architecture

```
                     devflow (orchestrator)
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
        Phase 1         Phase 2         Phase 3
        Setup           Develop         Finish
                            │
                    ┌───────┴───────┐
                    │               │
               superpowers      autoresearch
               pipeline         auto-injected
                                    │
                           ┌────────┴────────┐
                           │    │       │    │
                          probe scenario fix security
                           ①¾    ②½   ③   ②¾
```

## The 3 Phases

```
Phase 1: Setup (project-level, one-time)
  ─────────────────────────────────────────
  Detect deps → bd init → gitnexus analyze → seed docs/
  → configure guardrails → install autoresearch

  Runs from setup.ps1/setup.sh or auto-detects when
  .beads/ or .gitnexus/ is missing on session start.

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

## Tool Injection Details

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
├── .claude/
│   ├── settings.json           # Project hooks
│   ├── settings.local.json     # Local overrides (gitignored)
│   └── hooks/
│       ├── devflow-init-check.ps1
│       └── guardrails-git.ps1
├── scripts/
│   ├── prd-to-beads.ps1
│   └── prd-to-beads.sh
├── docs/
│   ├── CONTEXT.md
│   ├── adr/
│   └── tdd/
└── docs/superpowers/specs/
```

devflow has no prompts directory. All subagent prompts are owned by
`superpowers-subagent-driven-development`. autoresearch is a separate
skill installed via `npx skills add`.

## Prerequisites

- **Node.js ≥ 18** + **Git**
- **beads** — `go install github.com/gastownhall/beads/cmd/bd@latest`
- **gitnexus** — `npm install -g gitnexus`
- **superpowers** — `/plugin install superpowers@claude-plugins-official`
- **autoresearch** — installed by default via `npx skills add uditgoenka/autoresearch`
- **Python ≥ 3.10 + uv** (only for autoresearch ML mode)

## Setup for New Project

```bash
# From project root:
# PowerShell:
.\setup.ps1
# or bash:
# bash setup.sh

# This runs Phase 1: checks deps, bd init, gitnexus analyze,
# seeds docs/, installs guardrails, installs autoresearch.

# To skip autoresearch:
# $env:DEVFLOW_NO_AUTORESEARCH=1; .\setup.ps1
```

## Mid-Session New Task Handling

When the user proposes a new task mid-pipeline (e.g., during implementation ③), the pipeline is **not** linear-only. Handle based on scope:

### Classification

| If the request is... | Then... |
|----------------------|---------|
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
