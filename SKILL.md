---
name: devflow
description: 7-phase standard development workflow (Phase 0-6). Triggers on any development task — build, fix, refactor, optimize. Routes through brainstorm → plan → worktree → implement → review → finish, invoking tdd and superpowers skills at each phase.
---

# Standard Development Workflow

## Architecture

This skill is the **orchestrator**. It does not replace the specialized skills — it routes to them:

| Phase | Routes to |
|-------|-----------|
| 1. Brainstorming | `superpowers-brainstorming` |
| 2. Writing Plans | `superpowers-writing-plans` |
| 3. Git Worktree | `superpowers-using-git-worktrees` |
| 4. Implementation | `tdd` (mattpocock RED-GREEN-REFACTOR) + `superpowers-subagent-driven-development` |
| 5. Code Review | `superpowers-requesting-code-review` + `superpowers-receiving-code-review` |
| 6. Finish | `superpowers-finishing-a-development-branch` + `superpowers-verification-before-completion` |

## 7 Phases Overview

```
Phase 0: Environment Check
  Detect → Install deps → Init project → Prime context → Report
  (auto-runs on session start)

Phase 1: Brainstorming (superpowers-brainstorming)
  Explore → Clarify → Spec → Design doc → Review → User signs off

Phase 2: Writing Plans (superpowers-writing-plans)
  Split tasks (5-15min each) → Create beads issues → Verify plan → User signs off

Phase 3: Git Worktree (superpowers-using-git-worktrees)
  Create isolated branch → Init env → Baseline tests → Report

Phase 4: Implementation (tdd + superpowers-subagent-driven-development)
  beads create → gitnexus impact → Choose mode:
    ├─ General dev: Subagent 3-stage (Implement → Spec Review → Quality Review)
    └─ ML tuning:   Autoresearch loop (modify → experiment → evaluate → keep/discard)
  gitnexus detect_changes → beads close

Phase 5: Code Review (superpowers-requesting-code-review)
  Critical=fix now / Important=fix before proceed / Suggestion=record

Phase 6: Finish (superpowers-finishing-a-development-branch)
  Verify → 4 options (merge/PR/keep/discard) → Push → Clean → beads close
```

## Setup for New Project

To use this workflow in a new project:

```bash
# 1. Superpowers & TDD (one-time, any project)
# Already installed globally if you see this skill.

# 2. Initialize project context
bd init                                            # beads tracker
npx gitnexus analyze --force                       # code graph index

# 3. Copy workflow.md + prompts (from existing project template)
# Or just start — this skill routes to the right phases automatically.
```

## Prerequisites

- **beads** — `go install github.com/gastownhall/beads/cmd/bd@latest`
- **gitnexus** — `npm install -g gitnexus`
- **Node.js ≥ 18** + **Git**
- **Python ≥ 3.10** + **uv** (only for Autoresearch ML mode)

## Rules

- Build verification is **mandatory** before commit — run `npm run build` (or equivalent)
- Code is not done until `git push` succeeds
- 3-round max for subagent review loops; same issue 2nd time → escalate to human
- No production code without a failing test first (mattpocock_skills TDD discipline)
