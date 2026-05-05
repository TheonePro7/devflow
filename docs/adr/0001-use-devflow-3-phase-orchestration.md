# 0001 — Use devflow 3-Phase Orchestration

## Status

accepted

## Context

The project needed a structured development workflow that integrates:
- Task tracking (beads) — for issue lifecycle across sessions
- Code knowledge graph (gitnexus) — for context-aware subagents
- superpowers pipeline — for brainstorming, planning, implementation, review
- Autonomous improvement loops (autoresearch) — on-demand debugging/refactoring

Previously these tools operated independently with no orchestration layer,
leading to duplicate prompts, inconsistent task tracking, and missed context.

## Decision

Adopt a 3-phase orchestration model:

- **Phase 1 (Setup)**: Initialize beads + gitnexus once per project
- **Phase 2 (Develop)**: Delegate to superpowers pipeline with tool injection
- **Phase 3 (Finish)**: Close beads issues, generate session report

devflow does not reimplement any superpowers stage. It only injects beads
and gitnexus context at defined pipeline points.

Tool injection points:
1. Before brainstorming — beads epic issue + gitnexus context
2. Before writing-plans — beads sub-issues + gitnexus impact analysis
3. During implementation — gitnexus context for subagents + beads ready check

Additionally, borrow proven patterns from mattpocock/skills:
- Git guardrails (PreToolUse hook) — block dangerous git commands
- Plan-grill session — CONTEXT.md + ADR-based challenge between brainstorm and plan
- PRD→beads auto-split — parse design docs into tracked issues
- TDD deep reference docs — testing philosophy guides for subagents

## Consequences

- Single-entry workflow: setup → develop → finish with no skipped phases
- Reduced prompt duplication (devflow owns orchestration, superpowers owns pipeline)
- New projects need Phase 1 setup before dev sessions can start
- Guardrails hook adds slight overhead to every Bash command (sync check)

## Addendum 1: GitNexus SIGSEGV Exception (2026-05-05)

Dogfooding revealed that `gitnexus analyze` segfaults (SIGSEGV, exit 139) on
Windows/bash with Node 22 due to a tree-sitter native module crash. This is an
upstream issue, not fixable from devflow.

**Decision**: Phase 1 now supports "degraded" mode — if gitnexus analyze fails,
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
which is complementary to devflow's Phase 3 close flow.
