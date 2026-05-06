# Superpowers Skills — Complete In-Depth Analysis

> Generated from reading all 14 SKILL.md files at `C:\Users\Administrator\.claude\superpowers\skills/*/SKILL.md`
> Each skill is analyzed for: full description, complete process steps, HARD GATE annotations, input/output expectations, integration with other skills, tool injection points, and core spirit.

---

## Table of Contents

1. [using-superpowers](#1-using-superpowers)
2. [brainstorming](#2-brainstorming)
3. [writing-plans](#3-writing-plans)
4. [writing-skills](#4-writing-skills)
5. [subagent-driven-development](#5-subagent-driven-development)
6. [executing-plans](#6-executing-plans)
7. [test-driven-development](#7-test-driven-development)
8. [dispatching-parallel-agents](#8-dispatching-parallel-agents)
9. [systematic-debugging](#9-systematic-debugging)
10. [requesting-code-review](#10-requesting-code-review)
11. [receiving-code-review](#11-receiving-code-review)
12. [using-git-worktrees](#12-using-git-worktrees)
13. [finishing-a-development-branch](#13-finishing-a-development-branch)
14. [verification-before-completion](#14-verification-before-completion)

---

## 1. using-superpowers

### Full Name
`using-superpowers`

### Description
"Use when starting any conversation — establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions"

### Complete Process Steps
1. User message received
2. Check if any skill might apply (even 1% chance)
3. If yes -> Invoke Skill tool -> Announce "Using [skill] to [purpose]" -> Follow skill exactly
4. If skill has checklist -> Create TodoWrite per item
5. If no skill applies -> Respond (including clarifications)
6. If about to EnterPlanMode -> Check if already brainstormed -> If not, invoke brainstorming

### HARD GATE Annotations
- **`<EXTREMELY-IMPORTANT>`**: If you think there is even a 1% chance a skill might apply, you ABSOLUTELY MUST invoke the skill. IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT. This is not negotiable.
- **`<SUBAGENT-STOP>`**: If you were dispatched as a subagent to execute a specific task, skip this skill.
- Skill check comes BEFORE clarifying questions — this ordering is enforced.
- Skill check comes BEFORE codebase exploration.
- "I'm using the using-git-worktrees skill to set up an isolated workspace" format for announcements.
- Skills override default system prompt, but user instructions (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) take highest priority.

### Input/Output Expectations
- **Input:** Any user request or task
- **Output:** Appropriate skill invoked and followed, or structured approach determined

### Integration with Other Skills
- **Entry point for ALL skills** — the router that dispatches to all other skills
- Invokes brainstorming if not yet brainstormed and about to do creative work
- Provides platform adaptation: Skill tool (Claude Code), skill tool (Copilot CLI), activate_skill (Gemini CLI)

### Tool Injection Points
- Skill tool (primary)
- TodoWrite (for checklist tracking)
- Read (never to read skill files — use Skill tool instead)

### Core Spirit
**Skills are mandatory, not optional.** The "1% chance" rule means the cost of a false positive (wasting a moment reading irrelevant skill content) is vastly lower than the cost of a false negative (missing a skill that prevents wasted work). The 12-row rationalization prevention table explicitly targets every possible excuse to skip the skill check. This skill is the gatekeeper of the entire superpowers system — without it, no other skill would be invoked.

---

## 2. brainstorming

### Full Name
`brainstorming`

### Description
"You MUST use this before any creative work — creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."

### Complete Process Steps
1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (if visual questions anticipated) — MUST be its own message with no other content. Offer only a consent question. If declined, proceed with text-only.
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria. Before asking, assess scope: if request describes multiple independent subsystems, flag immediately and decompose first. Each sub-project gets its own spec -> plan -> implementation cycle.
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Present design** — in sections scaled to complexity. Ask after each section. Cover: architecture, components, data flow, error handling, testing.
6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
7. **Spec self-review** — Placeholder scan (TBD/TODO), Internal consistency (contradictions), Scope check (focused enough for single plan?), Ambiguity check (interpreted two ways?). Fix inline.
8. **User reviews written spec** — "Spec written and committed to <path>. Please review it and let me know if you want to make any changes before we start writing out the implementation plan." Wait for response. If changes, fix and re-run spec review loop.
9. **Transition to implementation** — invoke writing-plans skill. Do NOT invoke any other skill.

### HARD GATE Annotations
- **`<HARD-GATE>`**: Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. Applies to EVERY project regardless of perceived simplicity.
- **Anti-Pattern section**: "This Is Too Simple To Need A Design" — even a todo list, single-function utility, or config change must go through this process. "Simple" projects are where unexamined assumptions cause the most wasted work.
- **Terminal state enforcement**: The ONLY skill you invoke after brainstorming is writing-plans. NOT frontend-design, mcp-builder, or any other implementation skill.
- One question per message only.

### Input/Output Expectations
- **Input:** User's vague idea or feature request; project context (files, docs, commits)
- **Output:** Validated design document at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`; transition to writing-plans

### Integration with Other Skills
- **Calls:** `writing-plans` (mandatory next step)
- **May use:** `elements-of-style:writing-clearly-and-concisely` if available
- **Called by:** `using-superpowers` (automatic routing)
- **Creates worktree for:** Dedicated worktree for implementation (referenced by writing-plans)
- **Invited skills:** writing-plans (terminal state)

### Tool Injection Points
- Skill tool (invoke writing-plans)
- Visual companion tool (browser-based mockups/diagrams)
- Git for committing design doc
- Read for project context exploration
- Write for design doc file
- TodoWrite for checklist tracking

### Core Spirit
**Design-first, code-second. No exceptions.** Prevents wasted work by forcing structured exploration of user intent before any implementation. The visual companion offer is deliberately isolated as its own message (not combined with questions) to give the user a clear choice. Projects that are "too large" get decomposed into sub-projects first, then each gets the full cycle. Design principles emphasize small, focused units with well-defined interfaces — this is the same philosophy that drives the file structure guidance in writing-plans and the task isolation in subagent-driven-development.

---

## 3. writing-plans

### Full Name
`writing-plans`

### Description
"Use when you have a spec or requirements for a multi-step task, before touching code"

### Complete Process Steps
1. **Announce**: "I'm using the writing-plans skill to create the implementation plan."
2. **Scope Check** — if spec covers multiple independent subsystems, suggest breaking into separate plans (one per subsystem). Each plan should produce working, testable software on its own.
3. **File Structure** — Before defining tasks, map out which files will be created/modified and each one's responsibility. Design units with clear boundaries and well-defined interfaces. Prefer smaller, focused files. Files that change together should live together. In existing codebases, follow established patterns.
4. **Write plan document** with mandatory header:
   - `# [Feature Name] Implementation Plan`
   - `> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans`
   - Goal, Architecture (2-3 sentences), Tech Stack
5. **Define tasks** with structure: Task N, Files (create/modify/test), Steps with actual code, exact commands, expected output, commit step
6. **Self-Review** — Spec coverage (can you point to a task for each spec requirement?), Placeholder scan, Type consistency (signatures match across tasks?)
7. **Execution Handoff** — Offer two options: Subagent-Driven (recommended) or Inline Execution

### Bite-Sized Task Granularity
Each step is one action (2-5 minutes):
- "Write the failing test" -> step
- "Run it to make sure it fails" -> step
- "Implement the minimal code to make the test pass" -> step
- "Run the tests and make sure they pass" -> step
- "Commit" -> step

### HARD GATE Annotations
- **No Placeholders rule**: Every step must contain actual content. BANNED patterns:
  - "TBD", "TODO", "implement later", "fill in details"
  - "Add appropriate error handling" / "add validation" / "handle edge cases"
  - "Write tests for the above" (without actual test code)
  - "Similar to Task N" (repeat the code — engineer may read tasks out of order)
  - Steps that describe what to do without showing how
  - References to types/functions/methods not defined in any task
- **Complete code required**: If a step changes code, show the code
- **Exact commands required**: With expected output
- **Mandatory header**: Every plan MUST start with the agentic worker notice

### Input/Output Expectations
- **Input:** Validated spec/design document from brainstorming
- **Output:** Implementation plan at `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` with actionable checkbox tasks

### Integration with Other Skills
- **Called by:** `brainstorming` (mandatory terminal state)
- **Calls (execution handoff):** `subagent-driven-development` or `executing-plans`
- **Required context:** Should run in a dedicated worktree

### Tool Injection Points
- Write for plan file
- TodoWrite for task tracking
- Skill tool for execution handoff
- Git for commits (during execution, delegated)

### Core Spirit
**Zero-context-tolerant plans.** The plan assumes the implementing engineer has zero context for the codebase and questionable taste. Every detail must be explicit — complete code, exact paths, exact commands, expected output. The "Similar to Task N" rule exists because the engineer may read tasks out of order. TDD is baked into the step pattern (write failing test, verify fail, implement, verify pass, commit). The file structure mapping step ensures decomposition decisions are locked in before any code is written.

---

### Plan Document Header (Mandatory)
```markdown
# [Feature Name] Implementation Plan
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
  (recommended) or superpowers:executing-plans to implement this plan task-by-task.
**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies/libraries]
---
```

### Task Structure Template
Each task: name, files (create/modify/test), steps with actual code, exact commands, expected output.

### No Placeholders Rule
Every step must contain actual content. Plan failures:
- "TBD", "TODO", "implement later"
- "Add appropriate error handling" / "handle edge cases"
- "Write tests for the above" (without code)
- "Similar to Task N" (repeat code)
- References to undefined types/functions

### Self-Review (After Writing)
1. Spec coverage — can you point to a task for each spec requirement?
2. Placeholder scan — search for red flags
3. Type consistency — do signatures match across tasks?

### Execution Handoff
Offer two options:
1. **Subagent-Driven (recommended)** — `superpowers:subagent-driven-development`
2. **Inline Execution** — `superpowers:executing-plans`

### Tool Injection Points
- `TodoWrite` for task tracking
- `Read` for spec and context
- `Write` for plan file
- Git operations for commits
- `Skill` tool to invoke subagent-driven-development or executing-plans

### Integration
- **Called by:** `brainstorming` (terminal state)
- **Calls:** `subagent-driven-development` or `executing-plans`

---

## 4. writing-skills

### Full Name
`writing-skills`

### Description
"Use when creating new skills, editing existing skills, or verifying skills work before deployment"

### Complete Process Steps

**RED — Write Failing Test (Baseline):**
1. Create pressure scenarios (3+ combined pressures for discipline skills: time, sunk cost, authority, exhaustion)
2. Run scenarios WITHOUT skill — document exact behavior, rationalizations (verbatim), pressures that triggered violations
3. Identify patterns in failures

**GREEN — Write Minimal Skill:**
1. Write skill addressing those specific rationalizations only
2. Run same scenarios WITH skill — verify agent now complies

**REFACTOR — Close Loopholes:**
1. Identify NEW rationalizations from testing
2. Add explicit counters (for discipline skills)
3. Build rationalization table from all test iterations
4. Create red flags list
5. Re-test until bulletproof

**Deployment Checklist (mandatory for each skill):**
- Name: letters, numbers, hyphens only (no parentheses/special chars)
- YAML frontmatter with `name` and `description` (max 1024 chars)
- Description starts with "Use when..." with specific triggers/symptoms (NEVER summarize workflow)
- Written in third person
- Keywords throughout for search (errors, symptoms, tools)
- Clear overview with core principle
- Address specific baseline failures identified in RED
- One excellent example (not multi-language)
- Small flowchart only if decision non-obvious
- Quick reference table
- Common mistakes section
- No narrative storytelling
- Supporting files only for tools or heavy reference
- Commit skill to git and push
- STOP before moving to next skill — do NOT batch skills without testing each

### HARD GATE Annotations
- **The Iron Law**: NO SKILL WITHOUT A FAILING TEST FIRST. Applies to NEW skills AND EDITS to existing skills.
- Write skill before testing? Delete it. Start over. Edit skill without testing? Same violation.
- **No exceptions**: Not for "simple additions", not for "just adding a section", not for "documentation updates"
- Don't keep untested changes as "reference" — don't "adapt" while running tests — delete means delete
- REQUIRED BACKGROUND: You MUST understand `superpowers:test-driven-development` before using this skill
- Do NOT create multiple skills in batch without testing each
- Do NOT move to next skill before current one is verified
- Do NOT skip testing because "batching is more efficient"
- **Violating the letter of the rules is violating the spirit of the rules**

### Claude Search Optimization (CSO) — Critical Section
- **Description = When to Use, NOT What the Skill Does**: Testing revealed that when a description summarizes workflow, Claude may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality).
- Use concrete triggers, symptoms, and situations that signal this skill applies
- Describe the *problem* not *language-specific symptoms*
- Keep triggers technology-agnostic unless skill itself is technology-specific
- Keywords: error messages, symptoms, synonyms, tools
- Name by what you DO or core insight: `condition-based-waiting` > `async-test-helpers`
- Gerunds (-ing) work well for processes: `creating-skills`, `testing-skills`
- Cross-reference other skills with `**REQUIRED SUB-SKILL:** Use superpowers:name` — never use @ syntax (force-loads and burns context)

### Token Efficiency (Critical)
- Getting-started workflows: <150 words each
- Frequently-loaded skills: <200 words total
- Other skills: <500 words (be concise)
- Move details to tool help (--help), use cross-references, compress examples, eliminate redundancy

### Testing All Skill Types
- **Discipline-Enforcing Skills** (TDD, verification-before-completion): Test with academic questions + pressure scenarios + multiple pressures combined. Success: agent follows rule under maximum pressure.
- **Technique Skills** (how-to guides): Test with application scenarios + variation scenarios + missing information tests. Success: agent applies technique correctly.
- **Pattern Skills** (mental models): Test with recognition scenarios + application scenarios + counter-examples. Success: agent identifies when/how to apply pattern.
- **Reference Skills** (documentation/APIs): Test with retrieval scenarios + application scenarios + gap testing. Success: agent finds and applies reference information.

### Bulletproofing Skills Against Rationalization
- Close every loophole explicitly — forbid specific workarounds
- Address "spirit vs letter" arguments: "Violating the letter of the rules is violating the spirit of the rules"
- Build rationalization table from baseline testing
- Create red flags list for self-checking
- Update CSO for violation symptoms

### Input/Output Expectations
- **Input:** Identified need for a skill (recurring pattern, technique not intuitively obvious)
- **Output:** Tested, deployed SKILL.md with verified RED (baseline failure), GREEN (passing test), REFACTOR (closed loopholes)

### Integration with Other Skills
- **REQUIRED BACKGROUND:** `test-driven-development` (fundamental prerequisite)
- **Testing methodology:** `@testing-skills-with-subagents.md` (pressure scenarios, plugging holes, meta-testing)
- **Optional:** `anthropic-best-practices.md` (official Anthropic guidance)
- **Flowchart rendering:** `render-graphs.js` in skills directory

### Tool Injection Points
- Subagent dispatch (for pressure scenario testing)
- TodoWrite (for checklist tracking during creation)
- Read/Write for SKILL.md and supporting files
- Git for committing
- Graphviz DOT rendering (for flowcharts)
- `wc -w` for token efficiency verification

### Core Spirit
**Creating skills IS TDD for process documentation.** Same Iron Law, same RED-GREEN-REFACTOR cycle. The fundamental insight: untested skills have gaps — always. 15 minutes of testing saves hours debugging a bad skill in production. The skill is deeply meta — it demonstrates its own principles by including rationalization tables, red flag lists, explicit loophole closing, and CSO optimization. The CSO discovery about description fields is particularly elegant: descriptions that summarize workflow create a shortcut Claude will take, bypassing the skill body entirely.

---

## 5. subagent-driven-development

### Full Name
`subagent-driven-development`

### Description
"Use when executing implementation plans with independent tasks in the current session"

### Complete Process Steps

1. **Read plan file once** — extract ALL tasks with full text and context. Note context. Create TodoWrite with all tasks.
2. **Per-task loop:**
   a. **Dispatch implementer subagent** (using implementer-prompt.md) with full task text + context + scene-setting context
   b. **Handle implementer status**:
      - DONE -> Proceed to spec review
      - DONE_WITH_CONCERNS -> Read concerns, address if about correctness/scope, note observations and proceed
      - NEEDS_CONTEXT -> Provide missing context, re-dispatch
      - BLOCKED -> Assess: context problem (re-dispatch with more context)? Need more capable model (re-dispatch)? Task too large (break into smaller pieces)? Plan wrong (escalate to human)?
   c. **Dispatch spec compliance reviewer subagent** (spec-reviewer-prompt.md) — confirms code matches spec
   d. If spec issues found: implementer (same subagent) fixes them, reviewer reviews again. Repeat until approved.
   e. **Dispatch code quality reviewer subagent** (code-quality-reviewer-prompt.md) — evaluates code quality
   f. If quality issues: implementer (same subagent) fixes them, reviewer reviews again. Repeat until approved.
   g. Mark task complete in TodoWrite
   h. More tasks remain? -> loop to step 2a
3. **After all tasks:** Dispatch final code reviewer subagent for entire implementation
4. **Transition** to `superpowers:finishing-a-development-branch`

### Model Selection Strategy
- **Mechanical tasks** (isolated functions, clear specs, 1-2 files): fast/cheap model
- **Integration tasks** (multi-file coordination, pattern matching, debugging): standard model
- **Architecture/design/review tasks**: most capable model
- **Task complexity signals**: Touches 1-2 files with complete spec -> cheap model; Touches multiple files with integration -> standard model; Requires design judgment or broad codebase understanding -> most capable model

### HARD GATE Annotations
- **Two-stage review is MANDATORY**: spec compliance review first, THEN code quality review. Wrong order = red flag.
- **Never** skip reviews (spec compliance OR code quality)
- **Never** proceed with unfixed issues
- **Never** dispatch multiple implementation subagents in parallel (conflicts)
- **Never** make subagent read plan file (provide full text instead — controller extracts and provides)
- **Never** skip scene-setting context (subagent needs to understand where task fits)
- **Never** ignore subagent questions (answer before letting them proceed)
- **Never** accept "close enough" on spec compliance (reviewer found issues = not done)
- **Never** skip review loops (reviewer found issues = implementer fixes = review again)
- **Never** let implementer self-review replace actual review (both are needed)
- **Never** move to next task while either review has open issues
- **Never** start implementation on main/master branch without explicit user consent
- If implementer reports BLOCKED and plan is wrong -> escalate to human. **Never** force same model to retry without changes.

### Input/Output Expectations
- **Input:** Implementation plan with checkbox tasks (from writing-plans)
- **Output:** Implemented, tested, reviewed code; transition to finishing-a-development-branch

### Integration with Other Skills
- **Required sub-skills:** `using-git-worktrees` (isolated workspace), `writing-plans` (creates the plan), `requesting-code-review` (review templates), `finishing-a-development-branch` (completion)
- **Subagents use:** `test-driven-development` (TDD for each task)
- **Alternative workflow:** `executing-plans` (parallel session, no subagent support)

### Tool Injection Points
- Subagent dispatch (implementer, spec reviewer, code quality reviewer, final reviewer)
- Prompt templates: `implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`
- TodoWrite for task tracking
- Read for plan file (once, by controller)
- Skill tool (invoke finishing-a-development-branch)
- Git for commits per task

### Core Spirit
**Fresh subagent per task + two-stage review = high quality, fast iteration.** The key insight is context isolation: subagents should never inherit your session's history — you construct exactly what they need. This preserves your own context for coordination work. The controller curates exactly what context is needed; the subagent gets complete information upfront. Two-stage review (spec THEN quality) prevents over/under-building and ensures implementation is well-built. Self-review by the implementer is explicitly NOT a substitute for the formal review stages. The cost model is explicit: more subagent invocations but catches issues early (cheaper than debugging later).

---

## 6. executing-plans

### Full Name
`executing-plans`

### Description
"Use when you have a written implementation plan to execute in a separate session with review checkpoints"

### Complete Process Steps

**Step 1: Load and Review Plan**
1. Read plan file
2. Review critically — identify any questions or concerns about the plan
3. If concerns: raise with human partner before starting
4. If no concerns: Create TodoWrite and proceed

**Step 2: Execute Tasks**
For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

**Step 3: Complete Development**
After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill: verify tests, present options, execute choice

### HARD GATE Annotations
- **STOP executing immediately when**: hit a blocker, plan has critical gaps preventing starting, instruction unclear, verification fails repeatedly
- **Never** start implementation on main/master branch without explicit user consent
- **Never** force through blockers — stop and ask
- **Always** review plan critically first
- **Always** follow plan steps exactly
- **Always** run verifications as specified

### Input/Output Expectations
- **Input:** Written implementation plan (from writing-plans)
- **Output:** Implemented code; transition to finishing-a-development-branch

### Integration with Other Skills
- **Required workflow skills:** `using-git-worktrees` (isolated workspace), `writing-plans` (creates the plan), `finishing-a-development-branch` (completion)
- **Note:** Explicitly tells user that subagent-driven-development is superior when subagents are available
- **Called by:** writing-plans as inline execution option

### Tool Injection Points
- TodoWrite for task tracking
- Read for plan file
- Skill tool for finishing-a-development-branch
- Git for commits
- Test runner for verifications

### Core Spirit
**Faithful plan execution with critical review.** Load the plan, review it critically before starting, then follow steps exactly. The skill acknowledges its own limitations — it explicitly recommends subagent-driven-development as the superior alternative. Its value is in the parallel session scenario where you hand off the plan to a separate agent instance with fresh context. "Don't force through blockers — stop and ask" is the cardinal rule. This is the simplest of the implementation skills, intentionally so — it's designed for environments without subagent support.

---

## 7. test-driven-development

### Full Name
`test-driven-development`

### Description
"Use when implementing any feature or bugfix, before writing implementation code"

### Complete Process Steps

**RED — Write Failing Test:**
- Write one minimal test showing what should happen
- Requirements: one behavior, clear name, real code (no mocks unless unavoidable)
- Examples: GOOD (clear name: 'retries failed operations 3 times', tests real behavior, one thing); BAD (vague name: 'retry works', tests mock not code)

**Verify RED — Watch It Fail (MANDATORY):**
- Run test command
- Confirm: test fails (not errors), failure message is expected, fails because feature missing (not typos)
- Test passes? You're testing existing behavior. Fix test.
- Test errors? Fix error, re-run until it fails correctly.

**GREEN — Minimal Code:**
- Write simplest code to pass the test
- Don't add features, refactor other code, or "improve" beyond the test
- Examples: GOOD (just enough to pass); BAD (over-engineered with YAGNI violations)

**Verify GREEN — Watch It Pass (MANDATORY):**
- Run test command
- Confirm: test passes, other tests still pass, output pristine (no errors, warnings)
- Test fails? Fix code, not test.
- Other tests fail? Fix now.

**REFACTOR — Clean Up:**
- After green only: remove duplication, improve names, extract helpers
- Keep tests green. Don't add behavior.

**Repeat** — next failing test for next feature.

### HARD GATE Annotations
- **The Iron Law**: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
- Write code before the test? Delete it. Start over.
- **No exceptions**: Don't keep it as "reference", don't "adapt" it while writing tests, don't look at it. Delete means delete.
- Verification RED (watch fail) is MANDATORY. Never skip.
- Verification GREEN (watch pass) is MANDATORY. Never skip.
- **Violating the letter of the rules is violating the spirit of the rules.**
- Thinking "skip TDD just this once"? Stop. That's rationalization.

### Rationalization Prevention (16 excuses debunked)
| Excuse | Reality |
|---|---|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Already manually tested" | Ad-hoc =/= systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it. Add tests for existing code. |
| (And 5 more from the rationalization table in the skill)

### Red Flags — STOP and Start Over
- Code before test, test after implementation, test passes immediately, can't explain why test failed
- Tests added "later", rationalizing "just this once"
- "Tests after achieve the same purpose", "It's about spirit not ritual"
- "Keep as reference", "Already spent X hours, deleting is wasteful"
- All of these mean: Delete code. Start over with TDD.

### Verification Checklist
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

### Input/Output Expectations
- **Input:** Feature requirement or bug to fix
- **Output:** Tested code with failing-then-passing test cycle; failing test exists as regression guard

### Integration with Other Skills
- **Called by:** `systematic-debugging` (Phase 4, Step 1 — create failing test), `writing-skills` (required background)
- **Called by:** `subagent-driven-development` (subagents use TDD)
- **Called by:** `verification-before-completion` (verify fix worked)
- **Testing anti-patterns:** `@testing-anti-patterns.md` (avoid mocking pitfalls)

### Tool Injection Points
- Bash/PowerShell for test commands
- Read for existing code
- Write for test files and production code
- Git for commits

### Core Spirit
**If you didn't watch the test fail, you don't know if it tests the right thing.** Tests written after code pass immediately, which proves nothing — they might test the wrong thing, test implementation not behavior, or miss edge cases you forgot. Test-first forces you to see the test fail, proving it actually tests something. The sunk cost fallacy is addressed head-on: the time is already gone; your choice is between rewrite with TDD (high confidence) or keep unverified code (technical debt). The skill also serves as a design quality indicator: "hard to test = hard to use." The no-mocks principle forces dependency injection and clean interfaces.

---

## 8. dispatching-parallel-agents

### Full Name
`dispatching-parallel-agents`

### Description
"Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies"

### Complete Process Steps
1. **Identify Independent Domains** — group failures/tasks by what's broken. Each domain is independent (fixing one doesn't affect others).
2. **Create Focused Agent Tasks** — each agent gets: specific scope (one test file or subsystem), clear goal (make these tests pass), constraints (don't change other code), expected output (summary of what you found and fixed)
3. **Dispatch in Parallel** — one agent per problem domain, all run concurrently
4. **Review and Integrate** — read each summary, verify fixes don't conflict, run full test suite, integrate all changes

### Agent Prompt Structure
Good agent prompts:
1. **Focused** — one clear problem domain
2. **Self-contained** — all context needed to understand the problem
3. **Specific about output** — what should the agent return?

### HARD GATE Annotations
- **Don't use when**: failures are related (fix one might fix others), need to understand full system state, agents would interfere with each other (editing same files, using same resources), exploratory debugging (don't know what's broken yet)
- **Never** make prompts too broad ("fix all the tests") — agent gets lost
- **Never** provide no context or vague output expectations
- **Never** dispatch without constraints — agent might refactor everything

### Input/Output Expectations
- **Input:** Multiple independent problem domains (test failures, broken subsystems with error messages)
- **Output:** Each agent returns summary of root cause and changes; integrated final state with full test suite passing

### Integration with Other Skills
- **Contrasts with:** `subagent-driven-development` (which explicitly forbids parallel implementation subagents to avoid conflicts)
- **Called before:** verification step (review and integrate)
- **Can be called by:** Any context with independent failures to investigate

### Tool Injection Points
- Subagent/Task dispatch mechanism (parallel invocation)
- Test suite runner (final integration verification)

### Core Spirit
**Parallel investigation of independent problems.** When you have multiple unrelated failures, investigating them sequentially wastes time. The key insight is the strict independence check: if failures are related or share state, DON'T parallelize. The real-world example shows 6 failures across 3 files solved in the time of 1 by dispatching 3 agents in parallel. Each agent's scope is narrow (one test file), goals are clear, and output expectations are explicit. This is explicitly NOT for parallel implementation (subagent-driven-development forbids that) — it's for parallel investigation.

---

## 9. systematic-debugging

### Full Name
`systematic-debugging`

### Description
"Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes"

### Complete Process Steps

**Phase 1: Root Cause Investigation (BEFORE attempting ANY fix):**
1. Read error messages carefully — read stack traces completely, note line numbers/file paths/error codes
2. Reproduce consistently — exact steps, reliably every time? If not reproducible, gather more data, don't guess
3. Check recent changes — git diff, recent commits, new dependencies, config changes, environmental differences
4. Gather evidence in multi-component systems — add diagnostic instrumentation at EACH component boundary. Log what enters, what exits. Verify environment/config propagation. Check state at each layer. Run once to gather evidence showing WHERE it breaks, then analyze evidence to identify failing component, then investigate that specific component.
5. Trace data flow — backward tracing through call stack. Where does bad value originate? What called this with bad value? Keep tracing up until you find the source. Fix at source, not at symptom.

**Phase 2: Pattern Analysis:**
1. Find working examples in same codebase
2. Compare against references — read reference implementation COMPLETELY, don't skim, understand the pattern fully before applying
3. Identify differences between working and broken — list every difference, however small, don't assume "that can't matter"
4. Understand dependencies — what other components, settings, config, environment, assumptions?

**Phase 3: Hypothesis and Testing (Scientific method):**
1. Form single hypothesis — state clearly "I think X is the root cause because Y", be specific not vague
2. Test minimally — smallest possible change, one variable at a time, don't fix multiple things at once
3. Verify before continuing — worked? Phase 4. Didn't work? Form NEW hypothesis. DON'T add more fixes on top.
4. When you don't know — say "I don't understand X", don't pretend to know, ask for help, research more

**Phase 4: Implementation:**
1. Create failing test case — simplest possible reproduction, automated if possible, MUST have before fixing
2. Implement single fix — address the root cause identified, ONE change at a time, no "while I'm here" improvements, no bundled refactoring
3. Verify fix — test passes now? No other tests broken? Issue actually resolved?
4. If fix doesn't work — STOP. Count: how many fixes tried? If < 3: return to Phase 1. If >= 3: STOP and question the architecture. DON'T attempt Fix #4 without architectural discussion.
5. **If 3+ fixes failed: Question Architecture** — pattern indicating architectural problem: each fix reveals new shared state/coupling, fixes require "massive refactoring", each fix creates new symptoms elsewhere. STOP and question fundamentals. Discuss with human partner.

### HARD GATE Annotations
- **The Iron Law**: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
- If you haven't completed Phase 1, you cannot propose fixes
- You MUST complete each phase before proceeding to the next
- **Violating the letter of this process is violating the spirit of debugging**
- If 3+ fixes failed: architectural problem. Not a failed hypothesis — a wrong architecture.
- 95% of "no root cause" cases are incomplete investigation
- 16 red flag patterns that mean STOP (includes: "Quick fix for now, investigate later", "Just try changing X and see if it works", "One more fix attempt", proposing solutions before tracing data flow, etc.)

### Input/Output Expectations
- **Input:** Bug, test failure, unexpected behavior (with error messages or symptoms)
- **Output:** Root cause identified, fix implemented (one change), failing test created for regression, architecture questions surfaced (if 3+ fixes failed)

### Integration with Other Skills
- **Uses:** `test-driven-development` (Phase 4, Step 1 — create failing test case)
- **Uses:** `verification-before-completion` (verify fix worked before claiming success)
- **Supporting techniques in directory:** `root-cause-tracing.md` (backward tracing), `defense-in-depth.md` (multi-layer validation), `condition-based-waiting.md` (replace timeouts with polling)

### Tool Injection Points
- Bash/PowerShell for diagnostic commands (echo instrumentation at component boundaries)
- Read for error messages, logs, code, stack traces
- Git (diff, log for recent changes)
- Skill tool (invoke test-driven-development for regression tests)
- Test runner

### Core Spirit
**Root cause or nothing.** Random fixes waste time and create new bugs. Quick patches mask underlying issues. The four phases are a scientific method applied to debugging: gather evidence (Phase 1), find the pattern (Phase 2), form a hypothesis (Phase 3), fix at the source (Phase 4). The 3-fix rule is particularly important — after 3 failed fix attempts, the problem is likely architectural, not a simple bug, and no amount of further "fixing" will solve it without questioning fundamentals. The multi-component evidence gathering pattern is a standout: instrument every boundary, run once to see WHERE it breaks, THEN investigate that component. This prevents guessing at the wrong layer.

---

## 10. requesting-code-review

### Full Name
`requesting-code-review`

### Description
"Use when completing tasks, implementing major features, or before merging to verify work meets requirements"

### Complete Process Steps
1. **Get git SHAs**: `BASE_SHA=$(git rev-parse HEAD~1)` (or origin/main) and `HEAD_SHA=$(git rev-parse HEAD)`
2. **Dispatch code-reviewer subagent** with template from `code-reviewer.md`, filling placeholders:
   - `{WHAT_WAS_IMPLEMENTED}` — what you just built
   - `{PLAN_OR_REQUIREMENTS}` — what it should do
   - `{BASE_SHA}` — starting commit
   - `{HEAD_SHA}` — ending commit
   - `{DESCRIPTION}` — brief summary
3. **Act on feedback**:
   - Fix Critical issues immediately
   - Fix Important issues before proceeding
   - Note Minor issues for later
   - Push back if reviewer is wrong (with reasoning)

### HARD GATE Annotations
- **Never** skip review because "it's simple"
- **Never** ignore Critical issues
- **Never** proceed with unfixed Important issues
- **Never** argue with valid technical feedback
- If reviewer wrong: push back with technical reasoning, show code/tests that prove it works, request clarification

### Input/Output Expectations
- **Input:** Git SHAs (before/after), description of what was implemented, plan/requirements document
- **Output:** Review feedback with strengths, issues (severity-labeled: Critical/Important/Minor), assessment

### Integration with Other Skills
- **Used by:** `subagent-driven-development` (after EACH task — catch issues before they compound)
- **Used by:** `executing-plans` (after each batch of 3 tasks)
- **Used in:** Ad-hoc development (before merge, when stuck)
- **Uses template:** `requesting-code-review/code-reviewer.md`
- **Pairs with:** `receiving-code-review` (for evaluating and acting on feedback)

### Tool Injection Points
- Subagent dispatch (code-reviewer type)
- Bash for `git rev-parse`
- gh API (for PR-related reviews)

### Core Spirit
**Review early, review often.** Dispatch code-reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work. Feedback is categorized by severity (Critical, Important, Minor) with clear action requirements for each level.

---

## 11. receiving-code-review

### Full Name
`receiving-code-review`

### Description
"Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable — requires technical rigor and verification, not performative agreement or blind implementation"

### Complete Process Steps
1. **READ** — complete feedback without reacting
2. **UNDERSTAND** — restate requirement in own words (or ask)
3. **VERIFY** — check against codebase reality
4. **EVALUATE** — technically sound for THIS codebase?
5. **RESPOND** — technical acknowledgment or reasoned pushback
6. **IMPLEMENT** — one item at a time, test each

### Forbidden Responses
- **NEVER**: "You're absolutely right!", "Great point!", "Excellent feedback!", "Let me implement that now" (before verification)
- **INSTEAD**: Restate the technical requirement, ask clarifying questions, push back with technical reasoning, just start working (actions > words)
- **NEVER** express gratitude: "Thanks for [anything]" is explicitly forbidden. "Why no thanks: Actions speak. Just fix it. The code itself shows you heard the feedback."

### Handling Unclear Feedback
- If any item is unclear: STOP — do not implement anything yet — ask for clarification on unclear items
- WHY: Items may be related. Partial understanding = wrong implementation.

### Source-Specific Handling
- **From human partner**: Trusted — implement after understanding. Still ask if scope unclear. No performative agreement. Skip to action or technical acknowledgment.
- **From external reviewers**: Check: technically correct for THIS codebase? Breaks existing functionality? Reason for current implementation? Works on all platforms? Does reviewer understand full context? If suggestion seems wrong, push back with technical reasoning.

### YAGNI Check
If reviewer suggests "implementing properly", grep codebase for actual usage. If unused: "This endpoint isn't called. Remove it (YAGNI)?" If used, implement properly. Rule: "You and reviewer both report to me. If we don't need this feature, don't add it."

### Implementation Order for Multi-Item Feedback
1. Clarify anything unclear FIRST
2. Blocking issues (breaks, security)
3. Simple fixes (typos, imports)
4. Complex fixes (refactoring, logic)
5. Test each fix individually
6. Verify no regressions

### When to Push Back
Suggestion breaks existing functionality, reviewer lacks full context, violates YAGNI, technically incorrect for this stack, legacy/compatibility reasons, conflicts with human partner's architectural decisions. Use technical reasoning, not defensiveness.

### Gracefully Correcting Pushback
If you pushed back and were wrong: "You were right — I checked [X] and it does [Y]. Implementing now." No long apology, no defending why you pushed back, no over-explaining.

### HARD GATE Annotations
- **NEVER** performative agreement (explicit CLAUDE.md violation)
- **NEVER** blind implementation — verify against codebase first
- **NEVER** batch without testing each fix individually
- **NEVER** assume reviewer is right — check if it breaks things
- **NEVER** avoid pushback — technical correctness over comfort
- **NEVER** implement partially — clarify ALL items first
- **NEVER** proceed without verifying — state limitation, ask for direction

### Input/Output Expectations
- **Input:** Code review feedback (from human partner or external reviewer)
- **Output:** Verified implementation of agreed-upon feedback items; reasoned pushback for disagreed items

### Integration with Other Skills
- **Used after:** `requesting-code-review` delivers feedback
- **Pairs with:** `requesting-code-review` (two sides of the same code review coin)
- **GitHub integration:** Reply to inline review comments on GitHub as comment replies (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as top-level PR comments

### Tool Injection Points
- Grep (for YAGNI checks — grep codebase for actual usage)
- Read (for codebase verification)
- gh api (for GitHub comment replies)

### Core Spirit
**Technical correctness over social comfort.** Code review requires technical evaluation, not emotional performance. This is the most anti-performative skill in the system. "Thanks" is explicitly forbidden — actions speak, just fix it. External feedback = suggestions to evaluate, not orders to follow. The YAGNI check is particularly sharp: "implementing properly" from a reviewer triggers a grep for actual usage before any implementation. If the feature isn't used, push back to remove rather than "implement properly." The skill also provides a safe word ("Strange things are afoot at the Circle K") for situations where the agent feels socially uncomfortable pushing back.

---

## 12. using-git-worktrees

### Full Name
`using-git-worktrees`

### Description
"Use when starting feature work that needs isolation from current workspace or before executing implementation plans — creates isolated git worktrees with smart directory selection and safety verification"

### Complete Process Steps

**1. Directory Selection (Priority Order):**
- Check existing: `.worktrees/` (preferred, hidden) or `worktrees/` (alternative). If both exist, `.worktrees/` wins.
- Check CLAUDE.md for worktree directory preference
- If neither exists and no CLAUDE.md preference: ask user with two options:
  1. `.worktrees/` (project-local, hidden)
  2. `~/.config/superpowers/worktrees/<project-name>/` (global location)

**2. Safety Verification:**
- For project-local directories: MUST verify directory is ignored via `git check-ignore -q .worktrees`
- If NOT ignored: add appropriate line to .gitignore, commit the change (per "Fix broken things immediately"), then proceed
- For global directory: no .gitignore verification needed (outside project entirely)

**3. Creation Steps:**
1. Detect project name: `project=$(basename "$(git rev-parse --show-toplevel)")`
2. Create worktree: `git worktree add <path> -b <BRANCH_NAME>`
3. cd into path
4. Run project setup (auto-detect):

### Setup Auto-Detection
| File found | Command |
|---|---|
| package.json | npm install |
| Cargo.toml | cargo build |
| requirements.txt | pip install -r requirements.txt |
| pyproject.toml | poetry install |
| go.mod | go mod download |

**4. Verify Clean Baseline:** Run project-appropriate test command
- If tests fail: report failures, ask whether to proceed or investigate
- If tests pass: report ready

**5. Report Location:** "Worktree ready at <full-path>. Tests passing (<N> tests, 0 failures). Ready to implement <feature-name>."

### HARD GATE Annotations
- **Never** create worktree without verifying it's ignored (project-local)
- **Never** skip baseline test verification
- **Never** proceed with failing tests without asking
- **Never** assume directory location when ambiguous
- **Never** skip CLAUDE.md check
- **Always** follow directory priority: existing > CLAUDE.md > ask
- **Always** verify directory is ignored for project-local
- **Always** auto-detect and run project setup
- **Always** verify clean test baseline

### Input/Output Expectations
- **Input:** Feature/branch name, project path
- **Output:** Isolated worktree at determined path with clean test baseline

### Integration with Other Skills
- **Called by:** `brainstorming` (when design approved and implementation follows), `subagent-driven-development` (REQUIRED before executing tasks), `executing-plans` (REQUIRED before executing tasks)
- **Pairs with:** `finishing-a-development-branch` (REQUIRED for cleanup after work complete)

### Tool Injection Points
- Bash for git commands (`git worktree add`, `git check-ignore`, `git rev-parse`)
- Bash for project setup commands (npm, cargo, pip, poetry, go)
- Read for CLAUDE.md
- Write for .gitignore (if needed)
- Test suite runner

### Core Spirit
**Systematic directory selection + safety verification = reliable isolation.** The priority chain (existing directory > CLAUDE.md > ask user) eliminates ambiguity without requiring user input in most cases. The ignore verification prevents the catastrophic mistake of committing worktree contents to the repository. The clean baseline verification ensures that pre-existing test failures aren't confused with new bugs. The worktree is not just created — it's set up and verified before work begins.

---

## 13. finishing-a-development-branch

### Full Name
`finishing-a-development-branch`

### Description
"Use when implementation is complete, all tests pass, and you need to decide how to integrate the work — guides completion of development work by presenting structured options for merge, PR, or cleanup"

### Complete Process Steps

**Step 1: Verify Tests**
Run project's test suite. If tests fail: show failures. Stop. Cannot proceed until tests pass.

**Step 2: Determine Base Branch**
`git merge-base HEAD main` or `git merge-base HEAD master`. Ask: "This branch split from main — is that correct?"

**Step 3: Present Options (Exactly 4, concise, no explanation)**
1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

**Step 4: Execute Choice**

*Option 1 — Merge Locally:*
```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
<test command>  # verify tests on merged result
git branch -d <feature-branch>
```
Then: Cleanup worktree

*Option 2 — Push and Create PR:*
```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "<summary + test plan>"
```
Keep worktree (don't cleanup)

*Option 3 — Keep As-Is:*
Report: "Keeping branch <name>. Worktree preserved at <path>."
Do NOT cleanup worktree.

*Option 4 — Discard:*
Confirm first: "This will permanently delete: Branch <name>, All commits: <list>, Worktree at <path>. Type 'discard' to confirm."
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```
Then: Cleanup worktree

**Step 5: Cleanup Worktree**
For Options 1, 2, 4: check if in worktree, then `git worktree remove <path>`.
For Option 3: keep worktree.

### HARD GATE Annotations
- **Never** proceed with failing tests
- **Never** merge without verifying tests on result
- **Never** delete work without typed confirmation
- **Never** force-push without explicit request
- **Always** verify tests before offering options
- **Always** present exactly 4 options (no more, no less, no explanation)
- **Always** get typed "discard" confirmation for Option 4
- **Always** cleanup worktree for Options 1 & 4 only (NOT for 2 or 3)

### Input/Output Expectations
- **Input:** Completed implementation with passing tests; feature branch with commits
- **Output:** Chosen completion action executed (merge, PR created, kept, or discarded)

### Integration with Other Skills
- **Called by:** `subagent-driven-development` (Step 7 — after all tasks complete), `executing-plans` (Step 5 — after all batches)
- **Pairs with:** `using-git-worktrees` (cleans up worktree created by that skill)

### Quick Reference
| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|---|---|---|---|---|
| 1. Merge locally | Yes | - | - | Yes |
| 2. Create PR | - | Yes | Yes | - |
| 3. Keep as-is | - | - | Yes | - |
| 4. Discard | - | - | - | Yes (force) |

### Tool Injection Points
- Bash for test commands (npm test, cargo test, pytest, go test)
- Git commands: merge-base, checkout, pull, merge, branch -d/-D, push, worktree list/remove
- gh CLI for PR creation
- User input for option selection and typed "discard" confirmation

### Core Spirit
**Always verify tests first, then present clear options with no ambiguity.** The four options are fixed, concise, and leave no room for misinterpretation. Option 4 (discard) has a deliberate friction step requiring typed "discard" confirmation to prevent accidental data loss. The cleanup rules are precise: worktree is preserved for Options 2 (PR) and 3 (keep) because the branch still exists and work may continue; it's only cleaned up for Options 1 (merged, done) and 4 (discarded, gone).

---

## 14. verification-before-completion

### Full Name
`verification-before-completion`

### Description
"Use when about to claim work is complete, fixed, or passing, before committing or creating PRs — requires running verification commands and confirming output before making any success claims; evidence before assertions always"

### Complete Process Steps

**The Gate Function (5 steps):**
1. **IDENTIFY** — What command proves this claim?
2. **RUN** — Execute the FULL command (fresh, complete)
3. **READ** — Full output, check exit code, count failures
4. **VERIFY** — Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. **ONLY THEN** — Make the claim

Skip any step = lying, not verifying.

### HARD GATE Annotations
- **The Iron Law**: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
- If you haven't run the verification command in this message, you cannot claim it passes
- Skip any step = lying, not verifying
- **Violating the letter of this rule is violating the spirit of this rule.**
- **ALWAYS before**: any variation of success/completion claims, any expression of satisfaction, any positive statement about work state, committing, PR creation, task completion, moving to next task, delegating to agents
- **Rule applies to**: exact phrases, paraphrases, synonyms, implications of success, ANY communication suggesting completion/correctness

### Common Failures Table
| Claim | Requires | Not Sufficient |
|---|---|---|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

### Red Flags — STOP
- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!")
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- ANY wording implying success without having run verification

### Rationalization Prevention
| Excuse | Reality |
|---|---|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence =/= evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter =/= compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion =/= excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

### Key Patterns
- **Tests**: [Run test command] [See: 34/34 pass] "All tests pass" — not "Should pass now" / "Looks correct"
- **Regression (TDD Red-Green)**: Write -> Run(pass) -> Revert fix -> Run(MUST FAIL) -> Restore -> Run(pass)
- **Build**: [Run build] [See: exit 0] "Build passes" — linter doesn't check compilation
- **Requirements**: Re-read plan -> Create checklist -> Verify each -> Report gaps or completion
- **Agent delegation**: Agent reports success -> Check VCS diff -> Verify changes -> Report actual state

### Input/Output Expectations
- **Input:** Claim about work state (tests passing, bug fixed, linter clean, build succeeds, etc.)
- **Output:** Fresh verification evidence supporting or refuting the claim

### Integration with Other Skills
- **Used by:** ALL implementation/debugging skills — universal pre-completion gate
- **Used by:** `systematic-debugging` (verify fix worked before claiming success)
- **Used by:** `test-driven-development` (verify test passes)
- **Used by:** `finishing-a-development-branch` (verify tests before merge)
- **Pairs with:** EVERY skill that produces a completion claim

### Tool Injection Points
- Bash/PowerShell for verification commands (test runner, linter, build command)
- Read for command output inspection
- Git operations for VCS diff/changeset
- Any command that proves a claim

### Core Spirit
**Evidence before claims, always.** Claiming work is complete without verification is dishonesty, not efficiency. The skill exists because of 24 documented failure memories where trust was broken, undefined functions shipped, missing requirements shipped, and time was wasted on false completion -> redirect -> rework. The "common failures" table is exceptionally precise about what constitutes valid evidence vs. insufficient substitutes. "Agent completed" requires VCS diff showing changes — NOT the agent's success report. "Regression test works" requires the full Red-Green cycle — NOT the test just passing once. No shortcuts, no exceptions, no "just this once."

---

## Cross-Cutting Themes

### Process Skills vs. Implementation Skills
The system divides clearly into two layers:
- **Process/routing:** `using-superpowers` (entry point), `brainstorming` (design first), `writing-plans` (plan)
- **Execution:** `subagent-driven-development`, `executing-plans`, `systematic-debugging`
- **Quality:** `test-driven-development`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`
- **Infrastructure:** `using-git-worktrees`, `dispatching-parallel-agents`, `finishing-a-development-branch`
- **Meta:** `writing-skills`

### Three Cardinal Rules (The Iron Laws)
1. **No fixes without root cause investigation first** (systematic-debugging)
2. **No production code without a failing test first** (test-driven-development)
3. **No completion claims without fresh verification evidence** (verification-before-completion)
4. **No skill without a failing test first** (writing-skills)

### The HARD-GATE Pattern
Multiple skills use explicit gate annotations that block premature action. These are placed at critical transition points (before implementation, before fixes, before completion claims). They are paired with anti-rationalization tables and red flag lists that enumerate exactly what thoughts signal a violation in progress.

### Anti-Performative Culture
`receiving-code-review` is a standout: it explicitly forbids "You're absolutely right!", "Great point!", "Thanks!" — demanding technical evaluation over social comfort. This extends to `verification-before-completion` forbidding expressions of satisfaction before evidence. The system values technical honesty over politeness.

### Worktree Isolation Architecture
`using-git-worktrees` creates the physical isolation for feature work. `subagent-driven-development` adds cognitive isolation (fresh subagent per task, no inherited context). `finishing-a-development-branch` ensures cleanup. Together they form a complete isolation lifecycle.

### Two-Stage Review Pipeline
`subagent-driven-development` establishes a mandatory two-stage review:
1. **Spec compliance first** — does code match what was asked for? (prevents over/under-building)
2. **Code quality second** — is implementation well-built? (prevents technical debt)
The ordering is critical and enforced as a red flag.

### The "1% Chance" Rule
`using-superpowers` establishes that even a 1% chance a skill might apply is sufficient reason to invoke it. This is paired with a red flags table targeting 12 specific rationalizations for skipping the skill check.

### Skill Chain for a Feature (Full Flow)
1. `using-superpowers` -> triggers `brainstorming`
2. `brainstorming` -> design doc -> triggers `writing-plans`
3. `writing-plans` -> plan file -> triggers `subagent-driven-development` or `executing-plans`
4. `subagent-driven-development` -> per task: implement, then `requesting-code-review`
5. `finishing-a-development-branch` -> after all tasks: verify, present options, execute
6. `using-git-worktrees` -> cleanup (if worktree was used)

### Call Graph
```
using-superpowers (entry point)
  |
  v
brainstorming -> writing-plans -> writing-skills (meta-skill creation)
               /           \
              v             v
subagent-driven-development   executing-plans
              |                   |
              v                   v
        requesting-code-review (per-task)
        verification-before-completion (per-step)
              |                   |
              +----finishing-a-development-branch----+
                          |
                          v
                   using-git-worktrees (cleanup)
```

### Independent Skills (called directly as needed)
- `dispatching-parallel-agents` — independent task parallelization
- `systematic-debugging` — bug investigation (can call TDD for regression tests)
- `test-driven-development` — fundamental practice used by writing-skills and debugging
- `receiving-code-review` — response to code review feedback
- `verification-before-completion` — universal pre-completion gate

### Skills Referenced as Required by Other Skills

| Skill | Required By |
|---|---|
| `using-git-worktrees` | brainstorming, subagent-driven-development, executing-plans |
| `writing-plans` | brainstorming (terminal state) |
| `subagent-driven-development` | writing-plans (recommended execution) |
| `executing-plans` | writing-plans (alternative execution) |
| `finishing-a-development-branch` | subagent-driven-development, executing-plans |
| `test-driven-development` | writing-skills (required background), systematic-debugging |
| `requesting-code-review` | subagent-driven-development (per task) |

### Tool Injection Points Summary
| Tool | Used By |
|---|---|
| `Skill` (invoke) | using-superpowers, brainstorming, writing-plans, subagent-driven-development, executing-plans |
| `TodoWrite` | brainstorming, writing-plans, subagent-driven-development, executing-plans, writing-skills |
| `Task` (subagent dispatch) | subagent-driven-development, dispatching-parallel-agents, requesting-code-review, writing-skills |
| Bash/PowerShell | using-git-worktrees, finishing-a-development-branch, verification-before-completion, systematic-debugging, TDD |
| Git operations | using-git-worktrees, finishing-a-development-branch, requesting-code-review, brainstorming |
| `Read` | brainstorming, writing-plans, executing-plans, systematic-debugging, receiving-code-review |
| `Write` | brainstorming (design doc), writing-plans (plan file), writing-skills (SKILL.md) |
| `Grep` | receiving-code-review (YAGNI checks) |
| `gh api` | receiving-code-review (GitHub replies), requesting-code-review |

---

*Analysis complete. All 14 skills read in full and documented from source SKILL.md files.* |
