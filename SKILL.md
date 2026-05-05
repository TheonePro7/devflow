---
name: devflow
description: devflow Phase 1 pending — beads/gitnexus not initialized. SKILL: 3-PHASE ORCHESTRATOR (Setup → Develop → Finish). Wraps superpowers with beads + gitnexus + autoresearch. Use when hook reports Phase 1 pending or user invokes /devflow.
---

# devflow — Development Orchestrator

## Critical Rules

1. **devflow does not reimplement superpowers phases.** Brainstorming, writing plans, git worktrees, subagent-driven-development, code review, and branch finishing are all delegated to `superpowers-*` skills.
2. **devflow's value is tool injection** — beads task tracking, gitnexus code graph context, and autoresearch autonomous loop are injected at defined points in the superpowers pipeline.
3. **Phase 2 (Develop) is the main session loop.** It delegates to `superpowers-using-superpowers` for skill discovery, then injects tools at each pipeline stage.
4. **No code without spec sign-off.** Phase 2 respects superpowers' hard gate: brainstorming → plans → implementation.

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
   ┌────────┐ ┌───────────┐ ┌──────────┐
   │ beads  │ │superpowers│ │  beads   │
   │gitnexus│ │14 skills  │ │  close   │
   └────────┘ │           │ │  report  │
              │autore-    │ └──────────┘
              │search cmd │
              └───────────┘
```

## The 3 Phases

```
Phase 1: Setup (project-level, one-time)
  ─────────────────────────────────────────
  Detect deps → bd init → gitnexus analyze → configure

  Runs from setup.ps1/setup.sh or auto-detects when
  .beads/ or .gitnexus/ is missing on session start.

Phase 2: Develop (session-level, each task)
  ─────────────────────────────────────────
  Delegates to superpowers pipeline, injects tools:

  superpowers pipe           devflow injects
  ──────────────────         ──────────────
  brainstorming  ────────①── beads: create epic issue
                               gitnexus: context for design
  writing-plans  ────────②── beads: create sub-issues per task
                               gitnexus: impact analysis
  subagent-dev   ────────③── gitnexus context fed to subagents
                               beads: bd ready check
  code-review             (superpowers native, no devflow injection)
  finish-branch           (superpowers native)

  autoresearch:  Available as on-demand command (/autoresearch)
                 Not a phase — user invokes when needed

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
```

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
```

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
├── SKILL.md              # Orchestrator definition (this file)
├── setup.ps1             # Phase 1 Setup (Windows)
├── setup.sh              # Phase 1 Setup (Unix)
├── README.md
├── LICENSE
├── .gitignore
└── docs/superpowers/specs/# Design documents
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

# This runs Phase 1: checks deps, bd init, gitnexus analyze.
```

## Rules

- Build verification is **mandatory** before commit — run `npm run build` (or equivalent)
- Code is not done until `git push` succeeds
- TDD discipline enforced by superpowers-test-driven-development
- 3-round max for subagent review loops; escalate to human after 3
