# devflow

**Claude Code development workflow orchestrator — 3-phase (Setup → Develop → Finish) that enhances the superpowers pipeline with task tracking, code knowledge graph, and automated optimization gates.**

[中文版](README.md) • ![CI](https://github.com/TheonePro7/devflow/actions/workflows/ci.yml/badge.svg)

devflow is a lightweight orchestrator skill for [Claude Code](https://claude.ai/code). It wraps the [superpowers](https://github.com/obra/superpowers) 14-skill pipeline and injects **beads** (issue tracking), **gitnexus** (code knowledge graph), **autoresearch** (4 auto-gates), **plan-grill** (design cross-examination), **PRD-to-beads** (auto task splitting), and **TDD deep docs**. It also adopts Git guardrails, domain glossary (CONTEXT.md), and Architecture Decision Records (ADR) patterns from [mattpocock/skills](https://github.com/mattpocock/skills).

---

## Quick Start

**Prerequisites:** Go, Node.js >= 18, Git.

```bash
# 1. Clone devflow skill (one-time)
git clone https://github.com/TheonePro7/devflow.git ~/.claude/skills/devflow

# 2. Run installer from your project directory
cd your-project
bash ~/.claude/skills/devflow/install.sh

# 3. In Claude Code, type once:
# /plugin install superpowers@claude-plugins-official

# Done. Start a development task.
```

The installer auto-detects your OS, checks prerequisites, clones devflow, runs setup in **merge mode** (preserves all existing configs), and installs beads + gitnexus. See [Install & Setup](#install--setup) for details.

---

## Table of Contents

- [Architecture](#architecture)
- [Pipeline Overview](#pipeline-overview)
- [Features](#features)
- [Install & Setup](#install--setup)
- [Project Structure](#project-structure)
- [FAQ](#faq)
- [License & Acknowledgements](#license--acknowledgements)

---

## Architecture

devflow uses a 3-phase architecture, each with clear responsibilities:

```
                     devflow (orchestrator)
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
        Phase 1         Phase 2         Phase 3
        Setup           Develop         Finish
                            │
                    ┌───────┴───────┐
                    │               │
               superpowers      autoresearch
               pipeline         auto-injected
                                    │
                           ┌────────┴────────┐
                           │    │       │    │
                          probe scenario fix security
```

### Design Principles

| Principle | Description |
|-----------|-------------|
| **No reinvention** | devflow never reimplements what superpowers already does. Brainstorming, writing-plans, subagent-dev, code-review, finish-branch are all delegated to superpowers-* |
| **Tool injection** | devflow's value is injecting beads, gitnexus, grill, etc. at defined points in the superpowers pipeline |
| **Hard gates** | Phase 1 must complete before Phase 2. Plan-grill must pass before writing-plans |
| **HITL first** | Grill cross-examination and Phase 3 reports require human confirmation |
| **Secure by default** | Git guardrails block dangerous operations by default; overrides require explicit intent |

---

## Pipeline Overview

Each development task follows this automated pipeline in Claude Code:

```
User requests a feature
    │
    ▼
① superpowers-brainstorming
   devflow injects: beads epic + gitnexus context + CONTEXT.md
    │
    ▼
①½ PLAN-GRILL (HITL gate)
   Cross-examine design with CONTEXT.md + ADR + gitnexus
   Pass/fail decision by human
    │
    ▼
①¾ AUTORESEARCH PROBE ★ auto
   /autoresearch:probe — 8 adversarial personas find hidden constraints
    │
    ▼
② superpowers-writing-plans
   devflow injects: beads sub-issues + gitnexus impact + PRD→beads auto-split
    │
    ▼
②½ AUTORESEARCH SCENARIO ★ auto
   /autoresearch:scenario — 12-dimension edge case generation
    │
    ▼
③ superpowers-subagent-driven-development
   devflow injects: gitnexus context + beads ready + TDD deep docs
   ┌─ per-task: AUTORESEARCH:FIX zero-error gate ──────┐
   │ /autoresearch:fix --target "npm run build && npm test" │
   └────────────────────────────────────────────────────┘
    │
    ▼
superpowers-requesting-code-review
    │
    ▼
②¾ AUTORESEARCH SECURITY ★ auto
   /autoresearch:security --diff — STRIDE + OWASP Top 10 + red team audit
    │
    ▼
superpowers-finishing-a-development-branch

Background: Git guardrails PreToolUse hook (always active)
```

### Plan-Grill Gate

The plan-grill is a **mandatory human-in-the-loop gate** between brainstorming and writing-plans:

1. **Vocabulary verification** — Check all design terms against CONTEXT.md glossary
2. **ADR consistency** — Verify design doesn't conflict with past architecture decisions
3. **Code fact checking** — Use `gitnexus context <symbol>` to verify referenced code exists
4. **Dependency check** — Use `bd dep check` or `bd ready` to find unresolved blockers
5. **Edge case invention** — Proactively identify uncovered scenarios
6. **Output grill report** — Document term changes, blind spots found, and ADR alignment

---

## Features

### 1. Zero-Friction Install

```bash
# New to devflow?
git clone https://github.com/TheonePro7/devflow.git ~/.claude/skills/devflow
cd your-project
bash ~/.claude/skills/devflow/install.sh
```

Auto-detects OS, installs prerequisites, clones devflow, runs setup in merge mode. **No manual config needed.** Existing project settings (hooks, guardrails, .gitignore, docs) are detected and merged — never overwritten.

Offline or proxy install supported:

```bash
bash ~/.claude/skills/devflow/install.sh --offline
GIT_PROXY=http://proxy:8080 bash ~/.claude/skills/devflow/install.sh
```

### 2. Merge Semantics

Every component uses diff-and-append — never overwrite:

| Component | Merge Strategy | Idempotent |
|-----------|---------------|------------|
| **settings.json** | Hook dedup by (matcher, command, type, shell); path normalization for additionalDirectories | Second run says "already up to date" |
| **Guardrails** | Parse existing 12 patterns, append only missing ones | Existing patterns skipped |
| **.gitignore** | Exact line match, append only missing entries | Existing entries skipped |
| **CONTEXT.md** | Extract existing glossary terms, append new seed terms | No dupes |
| **ADR docs** | Diff existing index vs files on disk, append unlisted ADRs | Indexed ADRs skipped |
| **TDD docs** | Write templates on first run; user-modified files left alone | Existing files skipped |

On merge failure, original files are backed up automatically (e.g., `settings.json.bak`).

### 3. Task Tracking (beads)

- `bd create --title="..." --type=task|bug|feature` — Create issues
- `bd ready` — Find available work
- `bd update <id> --claim` — Claim a task atomically
- `bd close <id>` — Mark complete
- `bd dep add <a> <b>` — Set dependencies

PRD-to-beads auto-splits design documents with `## Task:` headings into beads issues:

```bash
bash scripts/prd-to-beads.sh -d docs/design.md -e "Feature Title"
```

### 4. Code Knowledge Graph (gitnexus)

- `gitnexus context <symbol>` — Pre-fetch code context for sub-agents
- `gitnexus impact <symbol> --depth 2` — Analyze change blast radius
- Automatically injected into brainstorming and implementation phases

### 5. Auto-Research Gates (autoresearch)

4 automatic gates along the pipeline, ON by default:

| Gate | Trigger | Purpose |
|------|---------|---------|
| **Probe** (①¾) | After grill | 8 adversarial personas find hidden constraints |
| **Scenario** (②½) | After plans | 12-dimension edge case generation |
| **Fix** (③) | Per-task | Iterative zero-error gate before next task |
| **Security** (②¾) | Before finish | STRIDE + OWASP + red team audit |

Opt-out: `DEVFLOW_NO_AUTORESEARCH=1` or tell the agent "skip probe/scenario/fix gate/security audit".

### 6. Git Guardrails

PreToolUse hook intercepts dangerous git commands **before** they execute:

| Blocked Command | Risk | Safe Alternative |
|----------------|------|-----------------|
| `git push --force` / `-f` | Overwrites remote history | `git push --force-with-lease` |
| `git reset --hard` | Discards uncommitted changes | `git reset --soft` or `git stash` |
| `git clean -fd` | Deletes untracked files | `git clean -n` to preview |
| `git branch -D` | Force-deletes unmerged branches | `git branch -d` |
| `git checkout .` / `git restore .` | Discards working tree changes | `git diff` to review first |
| `git rebase --skip` | Skips conflicted commits | Resolve conflicts manually |
| `git merge --abort` | Abandons merge | `git merge --continue` |

Override in `.claude/settings.local.json`:
```json
{
  "permissions": {
    "allow": ["Bash(git push --force origin hotfix-branch)"]
  }
}
```

---

## Install & Setup

### Fresh Install

```bash
git clone https://github.com/TheonePro7/devflow.git ~/.claude/skills/devflow
cd your-project
bash ~/.claude/skills/devflow/install.sh
```

**install.sh** auto-completes:
1. Check Go, Node.js, Git
2. Clone devflow (skip if exists)
3. Check superpowers skill readiness
4. Run setup in **merge mode** (preserve all existing configs)
5. Print next steps

> beads, gitnexus, and autoresearch are installed automatically. No manual `go install` or `npm install -g` needed.

### Windows

```powershell
powershell -File ~\.claude\skills\devflow\install.ps1
powershell -File ~\.claude\skills\devflow\install.ps1 --Offline
```

### Setup Modes: --merge vs --fresh

| Mode | Behavior | When to Use |
|------|----------|-------------|
| `--merge` (default) | Detect existing config → incremental append, **never overwrite** | Adding devflow to an existing project |
| `--fresh` | Fresh install (backup first, then overwrite) | New project or factory reset |

```bash
bash setup.sh --merge    # merge mode (recommended)
bash setup.sh --fresh    # clean install
```

### Verification

```bash
bd version          # beads works
gitnexus --version  # gitnexus works
ls .beads/          # Phase 1 complete
ls .gitnexus/       # code graph indexed
```

### Uninstall

Three-tier safety model:

| Tier | Level | Flags | Behavior |
|------|-------|-------|----------|
| **Tier 1** | Safe (auto) | `--hooks --guardrails --skill --autoresearch` | Auto-remove, no confirmation |
| **Tier 2** | Manual | `--docs` | Print removal instructions, user decides |
| **Tier 3** | Data loss | `--beads --gitnexus` (requires `--force`) | Warn before deleting issues/index |

```bash
bash uninstall.sh --hooks --guardrails --skill --autoresearch  # safe uninstall
bash uninstall.sh --all                                        # all safe components
bash uninstall.sh --all --force                                # complete removal
```

---

## Project Structure

```
devflow/
│
├── SKILL.md                        # Core orchestrator definition
├── setup.ps1 / setup.sh            # Phase 1 setup (--merge / --fresh)
├── install.ps1 / install.sh        # One-command installer
├── uninstall.ps1 / uninstall.sh    # Tiered safety uninstall
├── README.md / README.en.md        # Documentation (CN / EN)
├── AGENTS.md                       # AI agent shell tips
├── CLAUDE.md                       # AI agent conventions + beads workflow
├── LICENSE                         # MIT License
│
├── .github/workflows/
│   └── ci.yml                      # GitHub Actions CI (guardrails + merge tests)
│
├── .claude/
│   ├── settings.json               # Project Claude Code config
│   │   - SessionStart hook: Phase 1 detection
│   │   - PreToolUse hook: Git guardrails
│   │   - additionalDirectories: superpowers skill paths
│   │
│   └── hooks/
│       ├── devflow-init-check.ps1/sh  # SessionStart: Phase 1 status check
│       └── guardrails-git.ps1/sh      # PreToolUse: block dangerous git commands
│
├── scripts/
│   ├── prd-to-beads.ps1/sh        # Design doc → beads issues
│   ├── merge-settings.ps1/sh      # settings.json merge with hook dedup
│   ├── merge-guardrails.ps1/sh    # Guardrails pattern diff-and-append
│   ├── merge-gitignore.ps1/sh     # .gitignore exact-line merge
│   ├── merge-docs.ps1/sh          # CONTEXT.md + ADR + TDD merge
│   ├── check-superpowers.ps1/sh   # Superpowers installation check
│   └── test-*.ps1/sh              # Test suites (guardrails, merge)
│
├── docs/
│   ├── CONTEXT.md                 # Domain glossary (Ubiquitous Language)
│   ├── adr/                       # Architecture Decision Records
│   └── tdd/                       # TDD deep reference docs
```

---

## FAQ

### Q: SessionStart hook reports "devflow Phase 1 pending"?

A: Run `bash setup.sh` (Unix) or `.\setup.ps1` (Windows) to complete initialization.

### Q: Git guardrails blocked my command but I really need to run it?

A: Add the exact command to `.claude/settings.local.json`:
```json
"Bash(git push --force origin my-branch)"
```

### Q: Can I skip the grill gate?

A: Grill is a HITL gate and skipping is not recommended. If necessary, confirm "skip grill, confirmed aware of risks" when prompted.

### Q: How do I update devflow?

```bash
cd ~/.claude/skills/devflow
git pull
bash ~/.claude/skills/devflow/setup.sh --merge
```

### Q: How do I migrate to a new machine?

```bash
# One-command install on the new machine
cd your-project
bash ~/.claude/skills/devflow/install.sh
```

The `--merge` mode auto-detects and preserves existing configs.

### Q: What's the difference between beads and gitnexus?

A: **beads** is task tracking (issues, dependencies, status). **gitnexus** is a code knowledge graph (symbols, references, call relationships). beads answers "what to do", gitnexus answers "what the code looks like".

---

## License & Acknowledgements

**MIT License** — see [LICENSE](LICENSE).

This project incorporates design patterns and concepts inspired by:

| Project | Role | How devflow uses it |
|---------|------|-------------------|
| [obra/superpowers](https://github.com/obra/superpowers) | Core pipeline | Delegates brainstorming, writing-plans, subagent-dev, code-review, finish-branch |
| [beads](https://github.com/gastownhall/beads) | Task tracking | Auto-installed in Phase 1, creates/updates/closes issues |
| [gitnexus](https://www.npmjs.com/package/gitnexus) | Code graph | Auto-installed in Phase 1, provides context/impact to sub-agents |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Pattern source | Grill-with-docs → plan-grill; TDD docs; git guardrails; CONTEXT.md + ADR patterns |
| [autoresearch](https://github.com/uditgoenka/autoresearch) | Auto-optimization | 4 automatic gates (probe → scenario → fix → security). ON by default |

### What devflow doesn't do

- Doesn't reimplement any superpowers pipeline stages
- Doesn't include sub-agent prompt templates (managed by superpowers-subagent-driven-development)
- Doesn't replace CI/CD systems
- Doesn't manage deployment or infrastructure

---

*Happy coding!*
