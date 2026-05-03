---
name: devflow
description: IMPORTANT — 7-PHASE WORKFLOW. Triggers on ANY development task. FIRST do Phase 1 (Brainstorming). DO NOT skip to implementation. Phase order is MANDATORY.
---

# Standard Development Workflow

## CRITICAL RULES — Read First

1. **Phase order is MANDATORY.** Do NOT skip to implementation.
2. **Phase 1 (Brainstorming) MUST run first** — analyze requirements, clarify with user, get sign-off.
3. **No code without Phase 1 + Phase 2 sign-off.** User must approve spec AND plan before any implementation.
4. If user doesn't mention a phase, start from Phase 1 anyway.

## Architecture

This skill is the **orchestrator**. It does not replace the specialized skills — it routes to them:

| Phase | Routes to |
|-------|-----------|
| 0. Environment Check | auto-detect (beads + gitnexus + prompts) |
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

```bash
# 1. From project root, run setup script:
# PowerShell:
.\setup.ps1
# or bash:
# bash setup.sh

# 2. Or manually:
bd init                                            # beads tracker
npx gitnexus analyze --force                       # code graph index
# prompts are auto-copied by setup script
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
