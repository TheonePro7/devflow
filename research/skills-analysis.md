# mattpocock/skills — Deep Analysis

## Overview

**"Skills For Real Engineers"** by Matt Pocock — a collection of composable agent skills for Claude Code and Codex. Designed as an alternative to heavy frameworks (GSD, BMAD, Spec-Kit), emphasizing small, adaptable skills that work with any model.

- **Install:** `npx skills@latest add mattpocock/skills`
- **Setup:** Run `/setup-matt-pocock-skills` to configure issue tracker, triage labels, and docs location
- **Newsletter:** aihero.dev/s/skills-newsletter (~60,000 subscribers)

## The Four Core Problems & Their Solutions

| Problem | Solution | Skill |
|---------|----------|-------|
| Agent didn't do what you want | Grilling sessions — agent asks detailed questions before starting | `/grill-me`, `/grill-with-docs` |
| Agent is way too verbose | Shared language document (CONTEXT.md) | Built into `/grill-with-docs` |
| Code doesn't work | Feedback loops via TDD and debugging | `/tdd`, `/diagnose` |
| Architecture decay (ball of mud) | Deliberate design focus | `/to-prd`, `/zoom-out`, `/improve-codebase-architecture` |

## Complete Skill Inventory

### Engineering Skills (10 skills)

#### 1. `/diagnose`
- **Description:** Disciplined diagnosis loop for hard bugs and performance regressions
- **File:** `skills/engineering/diagnose/SKILL.md` (7,163 bytes)
- **Subdirectory:** `scripts/`
- **6-phase methodology:**
  1. **Build a feedback loop** — fast, deterministic, agent-runnable pass/fail signal
     - 10 strategies: failing test, curl/HTTP script, CLI invocation with fixture, headless browser script, replaying trace, throwaway harness, property/fuzz loop, bisection harness, differential loop, human-in-the-loop bash script
     - Iterate for speed, signal sharpness, determinism
     - If impossible to build, stop and ask user for access/permission
  2. **Reproduce** — confirm loop produces user's described failure across multiple runs
  3. **Hypothesise** — generate 3-5 ranked, falsifiable hypotheses before testing any
  4. **Instrument** — one variable at a time, tagged debug logs with unique prefix (`[DEBUG-a4f2]`)
  5. **Fix + regression test** — write regression test before fix (if correct seam exists)
  6. **Cleanup + post-mortem** — remove instrumentation, delete prototypes, document what would have prevented the bug

#### 2. `/grill-with-docs`
- **Description:** Grilling session that challenges plan against existing domain model, sharpens terminology, and updates CONTEXT.md and ADRs inline
- **File:** `skills/engineering/grill-with-docs/SKILL.md` (3,552 bytes)
- **Supporting files:**
  - `CONTEXT-FORMAT.md` (3,145 bytes) — CONTEXT.md template and rules
  - `ADR-FORMAT.md` (2,766 bytes) — ADR template and rules
- **Process:**
  - Interview relentlessly, one question at a time
  - Challenge against glossary in CONTEXT.md
  - Sharpen fuzzy language with precise canonical terms
  - Discuss concrete scenarios probing edge cases
  - Cross-reference with code
  - Update CONTEXT.md inline as terms are resolved
  - Offer ADRs sparingly (only when: hard to reverse, surprising without context, result of real trade-off)

#### 3. `/triage`
- **Description:** Triage issues through a state machine driven by triage roles
- **File:** `skills/engineering/triage/SKILL.md`
- **Two category roles:** `bug`, `enhancement`
- **Five state roles:** `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`
- **Process:** Gather context -> Recommend -> Reproduce (bugs only) -> Grill (if needed) -> Apply outcome
- **Outcome actions:**
  - `ready-for-agent`: post agent brief comment
  - `ready-for-human`: similar brief but note why not delegable
  - `needs-info`: post triage notes with template
  - `wontfix` (bug): polite explanation, close
  - `wontfix` (enhancement): write to `.out-of-scope/`, link, close

#### 4. `/improve-codebase-architecture`
- **Description:** Find deepening opportunities in a codebase, informed by CONTEXT.md language and ADRs
- **File:** `skills/engineering/improve-codebase-architecture/SKILL.md` (5,140 bytes)
- **Supporting files:**
  - `DEEPENING.md` (2,565 bytes)
  - `INTERFACE-DESIGN.md` (2,725 bytes)
  - `LANGUAGE.md` (3,804 bytes) — glossary of architectural terms
- **Key glossary (from LANGUAGE.md):**
  - **Module** — anything with interface + implementation
  - **Interface** — everything caller must know (types, invariants, error modes, ordering, config)
  - **Depth** — leverage at the interface (deep = high leverage)
  - **Seam** — where an interface lives
  - **Adapter** — concrete thing satisfying interface at a seam
  - **Deletion test** — if complexity vanishes when module is deleted, it was pass-through
  - **One adapter = hypothetical seam, Two adapters = real seam**
- **Process:** Explore -> Present candidates -> Grilling loop

#### 5. `/setup-matt-pocock-skills`
- **Description:** Scaffolds per-repo config for all engineering skills
- **File:** `skills/engineering/setup-matt-pocock-skills/SKILL.md`
- **`disable-model-invocation: true`** — user-triggered only
- **Creates:**
  - `docs/agents/issue-tracker.md`
  - `docs/agents/triage-labels.md`
  - `docs/agents/domain.md`
  - Updates `CLAUDE.md` or `AGENTS.md` with `## Agent skills` block
- **Supports:** GitHub, GitLab, local markdown, Other (freeform prose)

#### 6. `/tdd`
- **Description:** Test-driven development with red-green-refactor loop
- **File:** `skills/engineering/tdd/SKILL.md` (4,395 bytes)
- **Supporting files:**
  - `deep-modules.md` (1,239 bytes)
  - `interface-design.md` (653 bytes)
  - `mocking.md` (1,481 bytes)
  - `refactoring.md` (387 bytes)
  - `tests.md` (1,640 bytes)
- **Core principle:** Tests verify behavior through public interfaces, not implementation details
- **Anti-pattern:** Horizontal slices (all tests first then all implementation)
- **Correct approach:** Vertical tracer bullets (one test -> one implementation -> repeat)
- **Workflow:**
  1. **Planning** — confirm interface changes, identify deep modules, list behaviors
  2. **Tracer bullet** — RED (test fails) -> GREEN (minimal code)
  3. **Incremental loop** — one test at a time, minimal code, no anticipation
  4. **Refactor** — only when all tests pass, never refactor while RED
  5. **Checklist per cycle** — behavior vs implementation, public interface only, minimal code

#### 7. `/to-issues`
- **Description:** Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices
- **File:** `skills/engineering/to-issues/SKILL.md`
- **Process:**
  1. Gather context from conversation or issue tracker
  2. Explore codebase for domain vocabulary
  3. Draft vertical slices (HITL or AFK)
  4. Quiz user on granularity, dependencies, HITL/AFK designation
  5. Publish issues in dependency order
- **Slice rules:** Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)

#### 8. `/to-prd`
- **Description:** Turn current conversation context into a PRD and publish to issue tracker
- **File:** `skills/engineering/to-prd/SKILL.md`
- **Key rule:** Do NOT interview the user — synthesize what you already know
- **PRD template includes:**
  - Problem Statement, Solution, User Stories (extensive numbered list)
  - Implementation Decisions (modules, interfaces, architecture, schema, API contracts)
  - Testing Decisions (what makes a good test, which modules, prior art)
  - Out of Scope, Further Notes
- **Deep module focus:** Look for opportunities to extract modules that encapsulate lots of functionality in simple, rarely-changing interfaces

#### 9. `/zoom-out`
- **Description:** Tell the agent to zoom out and give broader context or higher-level perspective on unfamiliar code
- **File:** `skills/engineering/zoom-out/SKILL.md`
- Useful for onboarding to new codebases or understanding system architecture

#### 10. `/prototype`
- **Description:** Build a throwaway prototype to flush out a design
- Two modes: runnable terminal app for state/business-logic, or UI variations

### Productivity Skills (3 skills)

#### 1. `/caveman`
- Ultra-compressed communication mode
- Cuts token usage ~75%

#### 2. `/grill-me`
- **Description:** Interview user relentlessly about a plan until shared understanding
- **File:** `skills/productivity/grill-me/SKILL.md`
- Simpler version of grill-with-docs (no CONTEXT.md/ADR integration)
- One question at a time, provide recommended answer
- Explore codebase if question can be answered there

#### 3. `/write-a-skill`
- Guides creating new agent skills with proper structure
- Progressive documentation approach

### Misc Skills (5 skills)

- `git-guardrails-claude-code/` — git safety guardrails
- `migrate-to-shoehorn/` — migration utility
- `scaffold-exercises/` — exercise scaffolding
- `setup-pre-commit/` — pre-commit hook setup

### Deprecated & In-Progress
- `skills/deprecated/` — archived/removed skills
- `skills/in-progress/` — skills under development

### Personal Skills (2 skills)
- `edit-article/` — article editing workflow
- `obsidian-vault/` — Obsidian vault management

## Key Patterns & Conventions

### YAML Frontmatter
Every SKILL.md starts with:
```yaml
---
name: skill-name
description: Human-readable description of when to use
---
```

### Skill Structure
- **What-to-do** section via `<what-to-do>` tags (grill-with-docs pattern)
- **Supporting-info** section via `<supporting-info>` tags
- Cross-references to other skills and docs via relative paths

### Documentation Conventions

**CONTEXT.md Format:**
- One `CONTEXT.md` per domain context
- Structure: Context Name, Language (terms with definitions and aliases), Relationships, Example dialogue, Flagged ambiguities
- Rules: Be opinionated, flag conflicts explicitly, keep definitions tight (one sentence), show relationships with cardinality
- General programming concepts don't belong
- Multi-context repos use `CONTEXT-MAP.md` at root

**ADR Format:**
- Files in `docs/adr/` with sequential numbering: `0001-slug.md`
- Can be a single paragraph
- Optional: Status frontmatter, Considered Options, Consequences
- Only create when: hard to reverse, surprising without context, result of real trade-off

### Triage State Machine
```
Unlabeled -> needs-triage -> needs-info (waiting on reporter)
                           -> ready-for-agent (AFK-ready)
                           -> ready-for-human (needs human)
                           -> wontfix (closed)
needs-info -> needs-triage (when reporter replies)
```

### Vertical Slices Architecture
- Each issue is a thin vertical slice through ALL integration layers
- Prefer AFK (automated) over HITL (human-in-the-loop) where possible
- Published in dependency order so blocker IDs are known
- Issue template: What to build, Acceptance criteria, Blocked by

## Git Guardrails Pattern

The **git-guardrails-claude-code** skill (from mattpocock) is a PreToolUse hook that blocks 12 dangerous git patterns:

### Blocked Patterns (12 total)

```
git push --force     (not --force-with-lease)
git push -f          (short form)
git reset --hard     (not --soft)
git clean -fd        (force directory clean)
git clean -df        (alternate flag order)
git branch -D        (force delete, not -d)
git checkout .       (discard all working directory changes)
git checkout --      (discard specific files)
git restore .        (discard all via restore)
git restore --staged .  (unstage all)
git rebase --skip    (dangerous during rebase)
git merge --abort    (dangerous during merge)
```

### Implementation Pattern (from devflow local copy)

The hook receives stdin JSON:
```json
{"tool_name":"Bash","tool_input":{"command":"git push --force"}}
```

Returns JSON decision:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "DANGEROUS GIT COMMAND BLOCKED by guardrails: <pattern>"
  }
}
```

**Two parallel implementations required:**
- `.ps1` (PowerShell) — uses `ConvertFrom-Json` / `ConvertTo-Json`
- `.sh` (bash) — uses `grep`/`sed` for JSON parsing (no jq dependency)

Both must block the same 12 patterns and MUST be kept in sync.

### Guard Tests Pattern

Each implementation has a corresponding test script that validates:
- **Block tests:** 12 dangerous patterns must be denied
- **Allow tests:** 10+ safe patterns must be allowed
- **Edge cases:** `git push --force-with-lease` (allowed), `git reset --soft` (allowed)

Test scripts feed simulated stdin JSON and check for `permissionDecision.*deny` in output.

## Hooks System Pattern

mattpocock/skills establishes the hook architecture used by devflow:

### Hook Registration in settings.json

```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "..."}]}],
    "PreToolUse": [{"hooks": [{"type": "command", "command": "..."}]}],
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "..."}]}],
    "PreCompact": [{"hooks": [{"type": "command", "command": "..."}]}]
  }
}
```

### Hook Types Used
1. **SessionStart** — project initialization checks, context loading
2. **PreToolUse** — git safety guardrails, phase checks before Edit/Write
3. **UserPromptSubmit** — status reminders, state injection
4. **PreCompact** — data persistence (e.g., `bd prime` for beads)

## Skill Development Patterns

### SKILL.md Structure (from mattpocock conventions)

```yaml
---
name: skill-name
description: When to trigger this skill
---
```

Key structure elements:
- **YAML frontmatter** with name + description for auto-discovery
- **HARD-GATE** tags for non-skippable steps
- **SUBAGENT-STOP** tags for subagent mode
- **Checklist** with TodoWrite task creation
- **Reference files** in `references/` subdirectory
- **Scripts** in `scripts/` subdirectory
- **Supporting docs** for deep context (e.g., refactoring.md, tests.md)

### Key Patterns Adopted by devflow

1. **Dual-platform scripts** — `.ps1` + `.sh` for every automation (devflow has 8+ script pairs)
2. **JSON stdin/stdout hooks** — hooks receive context via stdin JSON, return decisions via stdout JSON
3. **Idempotent merge semantics** — install scripts detect existing config, append missing patterns only
4. **CONTEXT.md + ADR** — domain glossary + architecture decision records as persistent knowledge
5. **Grill protocol** — one-question-at-a-time interrogation with codebase cross-reference
6. **Vertical slice planning** — each task delivers a narrow but complete path through all layers
7. **Guard tests** — validate hook behavior via simulated input/output

## Integration with devflow

The skills system directly influences devflow's architecture:

1. **`/grill-with-docs`** -> devflow Phase 1 Ideate (structured discovery)
2. **`/to-prd`** -> devflow Phase 1 Ideate (PRD generation)
3. **`/setup-matt-pocock-skills`** -> devflow Phase 3 Setup (scaffolding)
4. **`/to-issues`** -> devflow `scripts/prd-to-beads.ps1` (task splitting)
5. **`/tdd`** -> devflow TDD skill integration
6. **`/diagnose`** -> referenced in devflow superpowers for debugging
7. **`/grill-me`** -> devflow "grill" step in Phase 4
8. **`CONTEXT.md`** -> devflow `docs/CONTEXT.md` pattern
9. **`docs/adr/`** -> devflow `docs/adr/` pattern
10. **Git guardrails** -> devflow `guardrails-git` scripts
