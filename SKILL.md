---
name: devflow
description: devflow Phase 1 pending — beads/gitnexus not initialized. SKILL: 3-PHASE ORCHESTRATOR (Setup → Develop → Finish). Wraps superpowers with beads + gitnexus + autoresearch. Use when hook reports Phase 1 pending or user invokes /devflow.
---

# devflow — Development Orchestrator

## Critical Rules

1. **devflow does not reimplement superpowers phases.** Brainstorming, writing plans, git worktrees, subagent-driven-development, code review, and branch finishing are all delegated to `superpowers-*` skills.
2. **devflow's value is tool injection** — beads task tracking, gitnexus code graph context, autoresearch, grill session, PRD→beads auto-split, and TDD deep docs are injected at defined points in the superpowers pipeline.
3. **Phase 2 (Develop) is the main session loop.** It delegates to `superpowers-using-superpowers` for skill discovery, then injects tools at each pipeline stage.
4. **No code without spec sign-off.** Phase 2 respects superpowers' hard gate: brainstorming → grill → plans → implementation + TDD.
5. **Git guardrails are always active.** Dangerous git commands (force push, reset --hard, etc.) are blocked by a PreToolUse hook. Override only through settings.local.json when intentional.

## Architecture

```
                     devflow (orchestrator)
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
        Phase 1         Phase 2         Phase 3
        Setup           Develop         Finish
            │               │               │
            │          ┌────┴────┐          │
            ▼          ▼         ▼          ▼
   ┌────────────────┐ ┌──────────────────┐ ┌──────────┐
   │ beads init     │ │ plan-grill ①½   │ │  beads   │
   │ gitnexus analyze│ │ superpowers pipe│ │  close   │
   │ CONTEXT.md seed │ │ PRD→beads      │ │  report  │
   │ ADR directory   │ │ TDD deep docs  │ └──────────┘
   │ guardrails hook │ │ autoresearch   │
   └────────────────┘ └──────────────────┘
        session-start       per-task            per-session
```

## The 3 Phases

```
Phase 1: Setup (project-level, one-time)
  ─────────────────────────────────────────
  Detect deps → bd init → gitnexus analyze → seed docs/
  → configure guardrails

  Runs from setup.ps1/setup.sh or auto-detects when
  .beads/ or .gitnexus/ is missing on session start.

  Creates:
  - docs/CONTEXT.md    (domain vocabulary template)
  - docs/adr/          (architecture decision records)
  - docs/tdd/          (TDD deep reference docs)
  - .claude/hooks/guardrails-git.ps1  (if not present)

Phase 2: Develop (session-level, each task)
  ─────────────────────────────────────────
  Delegates to superpowers pipeline, injects tools:

  superpowers pipe           devflow injects
  ──────────────────         ──────────────
  brainstorming  ────────①── beads: create epic issue
                                   gitnexus: context for design
                                   CONTEXT.md: domain vocab
  ═══ GRILL ════════════════①½══ challenge plan with
                                   CONTEXT.md + ADR + gitnexus
                                   refine terms, find blind spots
                                   → update CONTEXT.md
  writing-plans  ────────②── beads: create sub-issues per task
                                   gitnexus: impact analysis
                                   PRD→beads: auto-split tasks
  subagent-dev   ────────③── gitnexus context fed to subagents
                                   beads: bd ready check
                                   TDD deep docs: testing philosophy
  code-review             (superpowers native, no devflow injection)
  finish-branch           (superpowers native)

  autoresearch:  Available as on-demand command (/autoresearch)
                 Not a phase — user invokes when needed

  Background:    Git guardrails PreToolUse hook blocks dangerous
                 commands (--force, reset --hard, etc.) silently.

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
  - Captures the feature as a trackable top-level issue

gitnexus:
  - gitnexus context <key-symbol>  (if applicable)
  - Pre-fetched code context fed to brainstorming subagent

context:
  - Load docs/CONTEXT.md for domain vocabulary
  - Load docs/adr/ for past architectural decisions
```

### ①½ — Plan-Grill Injection (NEW)

After brainstorming produces a design direction, before writing plans:

> Inspired by mattpocock/skills — grill-with-docs

```yaml
Context:
  - Feed the brainstorming output + CONTEXT.md + relevant ADRs
    into a structured challenge session.

Process:
  1. Load CONTEXT.md — verify all terms used in the design are
     defined. Add missing terms.
  2. Load relevant ADRs — check if the design conflicts with
     past architectural decisions. Flag if so.
  3. gitnexus context — verify code-level facts assumed in the
     design (symbols exist, interfaces match, etc.).
  4. beads dep check — ensure no blocked dependency exists.
  5. Invent boundary cases — edge inputs, error states,
     concurrent access, etc. — that the design doesn't address.
  6. Output a grill summary to docs/superpowers/specs/ with:
     - Terms refined or added to CONTEXT.md
     - Blind spots found and resolved
     - Confirmed alignment with ADRs
```

The grill session is a human-in-the-loop (HITL) step. It MUST
present findings and get confirmation before proceeding to plans.

### ② — Writing Plans Injection

After plan is decomposed into tasks, before each task starts:

```yaml
beads:
  - bd create --title="<task>" --parent=<epic_id> --type=task
  - bd dep add <task> <dependency>  (if blocking relationship)
  - Tasks get hierarchical IDs: bd-xxx.1, bd-xxx.1.1, ...

gitnexus:
  - gitnexus impact <symbol> --depth 2
  - Blast radius data injected into plan context

auto-split (PRD→beads):
  - If the design doc has "## Task:" headings, run:
    scripts/prd-to-beads.ps1 (or .sh)
    -d docs/superpowers/specs/<design>.md
    -e "<epic-title>"
    -i <epic_id>
  - Creates one beads issue per task, sets dependencies
```

### ③ — Implementation Injection

During `superpowers-subagent-driven-development`:

```yaml
gitnexus:
  - Main agent pre-fetches gitnexus context for relevant symbols
  - Feeds context data to implementer/spec-reviewer/quality-reviewer subagents
  - Subagents do NOT run gitnexus themselves — parent agent passes data

beads:
  - bd ready  (check for blocking tasks before starting new work)
  - bd update <id> --claim  (atomic task assignment)

tdd-deep-docs:
  - In TDD mode, reference docs/tdd/*.md for:
    - deep-modules.md    — hiding complexity behind simple interfaces
    - interface-design.md— designing caller-first contracts
    - mocking.md         — mock only at system boundaries
    - refactoring.md     — one-step-at-a-time transformations
    - tests.md           — test behavior, not implementation
```

### Git Guardrails (Background)

A PreToolUse hook on Bash commands inspects every command for
dangerous git patterns:

- `git push --force` / `git push -f`
- `git reset --hard`
- `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When matched, the command is DENIED with a clear message.
To override: add the specific command to `.claude/settings.local.json`
allow array with explicit intent justification.

### autoresearch

Not a phase injection — registered as an available command:

- `/autoresearch:debug` — systematic bug hunting
- `/autoresearch:fix` — iterative repair until zero errors
- `/autoresearch:ship` — universal release workflow
- `/autoresearch:security` — STRIDE + OWASP audit
- `/autoresearch:plan` — interactive experiment design

Invoked on-demand by user or main agent when appropriate.

## Project Structure

```
devflow/
├── SKILL.md                    # Orchestrator definition (this file)
├── setup.ps1                   # Phase 1 Setup (Windows)
├── setup.sh                    # Phase 1 Setup (Unix)
├── README.md
├── LICENSE
├── .gitignore
├── .claude/
│   ├── settings.json           # Project hooks (SessionStart + PreToolUse)
│   ├── settings.local.json     # Local permissions overrides (gitignored)
│   └── hooks/
│       ├── devflow-init-check.ps1  # Phase 1 detection on session start
│       └── guardrails-git.ps1      # Dangerous git command blocker
├── scripts/
│   ├── prd-to-beads.ps1        # Design doc → beads issues (Windows)
│   └── prd-to-beads.sh         # Design doc → beads issues (Unix)
├── docs/
│   ├── CONTEXT.md              # Domain vocabulary (ubiquitous language)
│   ├── adr/                    # Architecture Decision Records
│   │   ├── README.md
│   │   └── 0001-use-devflow-3-phase-orchestration.md
│   └── tdd/                    # TDD deep reference docs
│       ├── deep-modules.md
│       ├── interface-design.md
│       ├── mocking.md
│       ├── refactoring.md
│       └── tests.md
└── docs/superpowers/specs/     # Design documents
```

devflow has no prompts directory. All subagent prompts are owned by
`superpowers-subagent-driven-development`.

## Prerequisites

- **Node.js ≥ 18** + **Git**
- **beads** — `go install github.com/gastownhall/beads/cmd/bd@latest`
- **gitnexus** — `npm install -g gitnexus`
- **superpowers** — `/plugin install superpowers@claude-plugins-official`
- **autoresearch** (optional) — `npx skills add uditgoenka/autoresearch`
- **Python ≥ 3.10 + uv** (only for autoresearch ML mode)

## Setup for New Project

```bash
# From project root:
# PowerShell:
.\setup.ps1
# or bash:
# bash setup.sh

# This runs Phase 1: checks deps, bd init, gitnexus analyze,
# seeds docs/CONTEXT.md, docs/adr/, docs/tdd/,
# and installs git guardrails hook.
```

## Rules

- Build verification is **mandatory** before commit — run `npm run build` (or equivalent)
- Code is not done until `git push` succeeds
- Git guardrails block dangerous operations — override consciously, not habitually
- Grill session is required between brainstorming and writing-plans (HITL gate)
- PRD→beads auto-split is preferred over manual bd create when design docs have tasks
- TDD discipline enforced by superpowers-test-driven-development + docs/tdd/ references
- CONTEXT.md and ADRs should be updated as the project's domain understanding evolves
- 3-round max for subagent review loops; escalate to human after 3
