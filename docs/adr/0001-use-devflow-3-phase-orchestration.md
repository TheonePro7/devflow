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
