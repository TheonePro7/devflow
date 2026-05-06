# Autoresearch (uditgoenka/autoresearch) — Deep Analysis

## Overview

**Autoresearch** is a skill/workflow system that transforms agentic coding tools into autonomous, self-improving loops. It generalizes Andrej Karpathy's original concept (a 630-line Python script for automated ML experimentation) into any domain: code, content, marketing, sales, HR, DevOps, design, or anything measurable by a number.

- **Creator:** Udit Goenka (uditgoenka)
- **Platforms:** Claude Code, OpenCode, OpenAI Codex, Gemini CLI
- **License:** MIT
- **Version:** v2.0.03
- **Install:** `npx skills add uditgoenka/autoresearch` or install script

## Core Philosophy

> "Set the GOAL -> The agent runs the LOOP -> You wake up to results"

Three key ingredients for compounding gains:
1. **Constraint** — clearly bounded scope (which files/folders can change)
2. **Mechanical metric** — objective, runnable evaluation (test suite, benchmark, score)
3. **Autonomous iteration** — the agent repeatedly: propose, test, keep-or-revert, log, repeat

## The Core Loop

```
LOOP (FOREVER or N times):
  1. Review state + git history + results log
  2. Pick next change (based on what worked/failed/is untried)
  3. Make ONE focused change
  4. Git commit (before verification)
  5. Run mechanical verification
  6. If improved -> keep. If worse -> git revert. If crashed -> fix or skip.
  7. Log the result (TSV format)
  8. Repeat until interrupted or N iterations complete
```

## 8 Critical Rules (Non-negotiable Guardrails)

1. **Loop until done** — bounded or unbounded
2. **Read before write** — understand full context first
3. **One change per iteration** — atomic; if it breaks, you know why
4. **Mechanical verification only** — no subjective "looks good"
5. **Automatic rollback** — failed changes revert instantly
6. **Simplicity wins** — equal results with less code = KEEP
7. **Git is memory** — `experiment:` prefix commits; agent must read `git log` + `git diff` before each iteration
8. **When stuck, think harder** — re-read, combine near-misses, try radical changes

## Complete Command Suite (11 Commands)

### PLAN Stage

**1. `/autoresearch`** — Run the main iteration loop
- Core autonomous improvement loop
- Modify -> Verify -> Keep/Discard -> Repeat
- Bounded (N iterations) or unbounded (infinite)

**2. `/autoresearch:plan`** — Interactive wizard for goal/metric/scope setup
- Guides user through defining the goal, mechanical metric, and scope
- Outputs a config that can be passed to `/autoresearch`

### LOOP Stage (implied by `/autoresearch`)
- The actual iteration engine
- Atomic changes with git rollback
- TSV logging of all results

### DEBUG Stage

**3. `/autoresearch:debug`** — Autonomous bug-hunting via scientific method
- Systematic exploration of failure modes
- Hypothesis -> experiment -> observation -> conclusion
- Designed for non-deterministic or hard-to-reproduce bugs

### FIX Stage

**4. `/autoresearch:fix`** — Iteratively repair errors until zero remain
- One-fix-per-iteration discipline
- Continues until all errors are resolved
- Automatic rollback on failed fixes

### SECURE Stage

**5. `/autoresearch:security`** — STRIDE + OWASP + red-team security audit
- Runs security analysis using multiple frameworks
- Identifies vulnerabilities and recommends fixes
- Can be sandboxed via Docker for safe execution

### SHIP Stage

**6. `/autoresearch:ship`** — Universal 8-phase shipping workflow
- Phases: Prepare, Validate, Build, Test, Package, Release, Verify, Announce
- Works for code, content, marketing, etc.
- Each phase has specific quality gates

### PROBE Stage

**7. `/autoresearch:probe`** — Adversarial requirement/assumption interrogation
- Uses 8 personas to probe the requirements
- Each persona has a different perspective (e.g., security expert, end user, QA engineer)
- Outputs a configuration for the loop

### SCENARIO Stage

**8. `/autoresearch:scenario`** — Use case & edge case generation
- Explores 12 dimensions of edge cases
- Generates comprehensive test scenarios
- Validates against real-world conditions

### PREDICT Stage

**9. `/autoresearch:predict`** — Multi-expert pre-analysis
- 5 perspectives analyze the problem before work begins
- Predicts outcomes, risks, and optimal approaches
- Useful for complex decisions

### LEARN Stage

**10. `/autoresearch:learn`** — Autonomous documentation engine
- Reads codebase and generates documentation
- Updates existing docs
- Can create comprehensive knowledge bases

### REASON Stage

**11. `/autoresearch:reason`** — Adversarial multi-agent debate for subjective content
- Blind judge panel evaluates competing positions
- Useful for design decisions, trade-off analysis
- Produces reasoned conclusions

## Command Chaining

Commands naturally chain together:
```
probe -> plan -> autoresearch
predict -> plan -> autoresearch -> fix -> security -> ship
```

## Platform Differences

| Platform | Command Syntax |
|----------|---------------|
| **Claude Code** | Colons (`/autoresearch:debug`) |
| **OpenCode** | Underscores (`/autoresearch_debug`) |
| **Codex** | `$autoresearch` mention syntax |

## Installation Methods

1. **Quick Install:** One-line curl/wget command
2. **CLAUDE.md (CLI persistence):** Adds skill reference to project CLAUDE.md
3. **Manual:** Clone repo, copy files, configure

Installers auto-detect environment (Claude Code vs OpenCode vs Codex) and set up platform-specific hooks.

## Security Sandbox

The **SECURE version** (`@secure`) runs inside a sandboxed Docker container:
- Mounts only permitted directories
- Blocks all network access by default
- Strips all capabilities (no root)
- Read-only by default with explicit temp volume
- 20+ safety rules including no curl/wget, no data exfiltration
- MANDATE file and emergency stop mechanisms

## Comparison with Karpathy's Original

| Dimension | Karpathy's Original | Claude Autoresearch |
|-----------|-------------------|-------------------|
| Domain | ML training only | Any domain with measurable metric |
| Interface | 1 command (`uv run train.py`) | 11 subcommands + interactive wizard |
| Hardware | NVIDIA GPU required | No special hardware |
| Files changed | Single file (`train.py`) | Any glob pattern |
| Guardrails | None | Guard command, crash recovery, stuck detection |
| Verification speed | ~5 min (12 exp/hr) | Seconds (~360 exp/hr) |

### 7 Shared Universals
1. **Constraint = Enabler** — tight scope forces focused exploration
2. **Strategy != Tactics** — human sets *what*, AI figures out *how*
3. **Mechanical Metrics** — objective scalar numbers
4. **Fast Verification** — cheap iteration enables bold exploration
5. **Iteration Cost -> Behavior** — lower cost = more experimentation
6. **Git as Memory** — every experiment tracked in version history
7. **Honest Limitations** — acknowledge what the system cannot do

## FAQ Highlights

- **No config needed** — just Claude Code/OpenCode/Codex with git access
- **Stopping:** Ctrl+C, "Stop", "Pause", or closing terminal
- **Metrics:** Any CLI-runnable measurement — `npm test`, `pytest`, `wc -l`, custom benchmarks
- **Failed loop recovery:** Restart and agent reads TSV to resume
- **Background runs:** `nohup` works; agent checks results on resumption
- **Behavior:** Determined by agent, not deterministic scripts

## Repository Structure

From GitHub API:
- `AGENTS.md` (10.9 KB)
- `COMPARISON.md` (31.5 KB) — detailed comparison with Karpathy
- `CONTRIBUTING.md` (16.5 KB)
- `README.md` (33.8 KB)
- Directories: `.agents/`, `.claude-plugin/`, `.claude/`, `.github/`, `.opencode/`

## Key Innovations Over Karpathy Original

1. **Domain generality** — not just ML, but any measurable task
2. **Rich command suite** — 11 specialized workflows
3. **Platform abstraction** — works across Claude Code, OpenCode, Codex
4. **Adversarial/multi-agent modes** — probe, predict, reason commands
5. **Security sandboxing** — Docker-based secure variant
6. **Interactive planning wizard** — `/autoresearch:plan`

## Detailed Workflow Architecture

### Interactive Setup Gates (Per Command)

Every command has a mandatory interactive setup when invoked without required context. Questions are always batched in a SINGLE call:

| Command | Required Context | Questions When Missing |
|---------|-----------------|----------------------|
| `$autoresearch` | Goal, Scope, Metric, Direction, Verify | Batch 1 (4 q) + Batch 2 (3 q) |
| `$autoresearch plan` | Goal | 1 question (goal wizard) |
| `$autoresearch debug` | Issue/Symptom, Scope | 4 questions |
| `$autoresearch fix` | Target, Scope | 4 questions (with pre-scan) |
| `$autoresearch security` | Scope, Depth | 3 questions |
| `$autoresearch ship` | What/Type, Mode | 3 questions |
| `$autoresearch scenario` | Scenario, Domain | 4-8 adaptive questions |
| `$autoresearch predict` | Scope, Goal | 3-4 batched questions |
| `$autoresearch learn` | Mode, Scope | 4 questions |
| `$autoresearch reason` | Task, Domain | 3-5 adaptive questions |
| `$autoresearch probe` | Topic | 4-7 adaptive questions |

### Loop Architecture

Each command follows a phased architecture:

```
Phase 0: Precondition Checks (before loop)
  - git repo exists + clean working tree + no stale locks
  - No detached HEAD + check for interfering hooks

Phase 1: Review (every iteration)
  1. Read current state of in-scope files
  2. Read last 10-20 entries from results log
  3. MUST run: git log --oneline -20 (see experiment history)
  4. MUST run: git diff HEAD~1 (review last kept change)
  5. Identify: what worked, what failed, what's untried
  6. If bounded: check current_iteration vs max_iterations

LOOP BODY (per iteration):
  Phase 3: Make ONE focused change
  Phase 4: Git commit (before verification)
  Phase 5: Run verification command
  Phase 6: Run guard command (if configured)
  Phase 7: Decision — keep (commit stays) / discard (revert) / crash
  Phase 8: Log to TSV
```

### Composite Metric Formulas

Each command has a domain-specific scoring formula:

| Command | Formula |
|---------|---------|
| Security | `(owasp_tested/10)*50 + (stride_tested/6)*30 + min(findings, 20)` (higher=better) |
| Ship | `(checklist_passing/total)*80 + (dry_run_passed?15:0) + (no_blockers?5:0)` |
| Scenario | `scenarios_generated*10 + edge_cases_found*15 + (dimensions_covered/12)*30 + unique_actors*5` |
| Probe | Dimensions saturation (net-new atoms < threshold for K rounds) |

### Results Logging Format (TSV)

File: `autoresearch-results.tsv` (gitignored)

```
iteration    commit    metric    delta    guard    guard-metric    status    description
```

Columns:
- `iteration` — Sequential counter (0 = baseline)
- `commit` — 7-char git hash, "-" if reverted
- `metric` — Measured value from verification
- `delta` — Change from previous best
- `guard` — `pass`, `fail`, or `-` (no guard)
- `guard-metric` — Float or "-"
- `status` — `baseline`, `keep`, `keep (reworked)`, `discard`, `crash`, `no-op`, `hook-blocked`, `metric-error`
- `description` — One-sentence summary of what was tried

### 7 Core Principles (Karpathy-derived)

1. **Constraint = Enabler** — bounded scope enables confidence, simplicity, velocity
2. **Separate Strategy from Tactics** — humans set direction, agents execute
3. **Metrics Must Be Mechanical** — if you can't `grep` it, you can't iterate
4. **Verification Must Be Fast** — slow verification kills iteration velocity
5. **Iteration Cost Shapes Behavior** — cheaper iteration = bolder exploration
6. **Git as Memory and Audit Trail** — commits track causality, history prevents repetition
7. **Honest Limitations** — state what the system can and cannot do

### Git-as-Memory Protocol

**Every iteration reads git history (mandatory):**

```bash
git log --oneline -20           # see experiment sequence
git diff HEAD~1                 # inspect last kept change
git log --oneline -20 | grep "experiment"  # what was tried
git show <hash> --stat          # deep-dive specific commit
```

**Commit naming convention:** `experiment(<scope>): <description>`

**Memory depth:** 20 commits default, configurable via `Memory-Depth: N`

### Platform-Specific Invocation

| Platform | Syntax | Notes |
|----------|--------|-------|
| **Claude Code** | `$autoresearch` | Uses Skill tool invocation |
| **Codex CLI** | `$autoresearch` | Same mention-based syntax |
| **OpenCode** | `$autoresearch` | Same mention-based syntax |
| **Gemini CLI** | `$autoresearch` | Uses `activate_skill` tool |

### Security Workflow Details

**STRIDE model:**
- Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege

**Assets audited:**
- Data stores, authentication, API endpoints, external services, user input surfaces, configuration, static assets

**Output** → `security/{YYMMDD}-{HHMM}-{audit-slug}/` with:
- `overview.md`, `threat-model.md`, `attack-surface-map.md`
- `findings.md`, `owasp-coverage.md`, `dependency-audit.md`
- `recommendations.md`, `security-audit-results.tsv`

**Flags:**
- `--diff` — delta mode (only changed files)
- `--fix` — auto-fix Critical/High findings
- `--fail-on {severity}` — CI/CD gating

### Fix Workflow Priority Order

1. Build failures (nothing works without compile)
2. Critical/High bugs (data loss, security)
3. Type errors (type safety prevents cascading bugs)
4. Test failures (tests verify correctness)
5. Medium/Low bugs
6. Lint errors (code quality)
7. Warnings (polish)

### Debug Workflow Experiment Types

1. Direct inspection (read code at suspected location)
2. Trace execution (add logging, run, read output)
3. Minimal reproduction (create smallest failing case)
4. Binary search (comment out half the code, narrow)
5. Differential (compare working vs broken via git diff)
6. Git bisect (find exact commit that introduced bug)
7. Input variation (change inputs systematically)

### Scenario Exploration Dimensions

12 dimensions for comprehensive coverage:
1. Happy path
2. Error handling
3. Edge cases
4. Abuse/misuse
5. Scale/load
6. Concurrent access
7. Temporal (timing, ordering)
8. Data variation
9. Permission/authorization
10. Integration/external dependencies
11. Recovery/resilience
12. State transitions
