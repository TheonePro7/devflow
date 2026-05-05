# ADR 0002 — Use State-Driven Execution with Four-Layer Enforcement

- **Status**: Accepted
- **Date**: 2026-05-05
- **Context**: "Agent has no consciousness, only memory" — direct quote from user. Agents consistently forget or skip devflow workflow steps, making the orchestrator ineffective.
- **Decision**: Implement a four-layer enforcement chain that agents cannot bypass:
  - Layer 0: Global SessionStart hook in `~/.claude/settings.json` detects new projects
  - Layer 1: SKILL.md new project auto-detect runs setup before any code
  - Layer 2: CLAUDE.md supreme directive loaded as system prompt every session
  - Layer 3: UserPromptSubmit hook refreshes state every message + PreToolUse hook physically blocks Edit|Write when phase is wrong
- **Consequences**:
  - Positive: Agents cannot forget devflow — every message and code edit is gated
  - Positive: New projects auto-initialize without user instruction
  - Negative: First-time users see devflow prompts even in non-devflow projects (mitigated by silent pass when `.devflow/state` exists)
