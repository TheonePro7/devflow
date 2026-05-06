# 0001 — Use devflow 5-Phase Orchestration (v0.2 update)

## Status

accepted (amended 2026-05-05: 3-phase → 5-phase)

## Context

devflow originally used a 3-phase orchestration (Setup → Develop → Finish)
focused on engineering workflows. Two gaps emerged:

1. **No product discovery phase** — Users with raw ideas lacked structured
   guidance to crystallize them into actionable PRDs.
2. **No frontend design phase** — Non-technical users had no path from
   PRD to a working frontend UI without hiring a designer or frontend engineer.

The original 3-phase architecture only served users who already knew what
they wanted to build and had the skills to build it.

## Decision (v0.2 Amendment)

Expand from 3 to 5 phases:

- **Phase 1 (Ideate)**: Claude-guided idea exploration → PRD
  - Structured questioning (target users, problem, existing solutions)
  - User personas, feature hypotheses (MoSCoW), risk analysis
  - No external tools — pure Claude conversation
- **Phase 2 (Design)**: PRD → Frontend scaffold
  - Claude direct generation (default) for most projects
  - screenshot-to-code integration for screenshot/Figma → code conversion
  - Component tree, UI architecture, API integration stubs
- **Phase 3 (Setup)**: Unchanged from 3-phase — beads + gitnexus + guardrails
- **Phase 4 (Develop)**: Unchanged from 3-phase — superpowers pipeline
- **Phase 5 (Finish)**: Unchanged from 3-phase — beads close + session report

Key integration details:
- Phase 1/2 are Claude-guided (not HITL gates) — no grill required
- screenshot-to-code is installed on-demand, not auto-installed
- PRD from Phase 1 feeds directly into Phase 4's brainstorming
- Frontend scaffold from Phase 2 sets up the UI layer for Phase 4 backend integration

## Addendum 1: GitNexus SIGSEGV Exception (2026-05-05)

Dogfooding revealed that `gitnexus analyze` segfaults (SIGSEGV, exit 139) on
Windows/bash with Node 22 due to a tree-sitter native module crash. This is an
upstream issue, not fixable from devflow.

**Decision**: Phase 3 now supports "degraded" mode — if gitnexus analyze fails,
the setup script continues with a warning. gitnexus code context will be
unavailable to subagents until the index is built manually.

**Workaround**: Run `gitnexus analyze . --force` in native PowerShell (not bash).

**Status**: Exception accepted. Will be removed when upstream is fixed.

## Addendum 2: beads Auto-Hook Behavior (2026-05-05)

`bd init` automatically adds `bd prime` hooks to `.claude/settings.json`
(PreCompact + SessionStart events). This is beads' expected behavior —
`--skip-hooks` and `--skip-agents` flags exist to disable it.

**Decision**: devflow does not prevent or override this. beads hooks and devflow
hooks coexist. If users prefer no beads hooks, re-run with:
  `bd init --skip-hooks --skip-agents`

**Note**: `bd prime` pre-compact hook improves session persistence for beads data,
which is complementary to devflow's Phase 5 close flow.
