# devflow

**7-phase standard development workflow for Claude Code.** Phase 0-6 orchestrating TDD, git worktrees, subagent-driven development, code review, and the obra/superpowers skill system.

```
Phase 0: Environment Check
Phase 1: Brainstorming    → superpowers-brainstorming
Phase 2: Writing Plans    → superpowers-writing-plans
Phase 3: Git Worktree     → superpowers-using-git-worktrees
Phase 4: Implementation   → tdd (RED-GREEN-REFACTOR) + subagent 3-stage review
Phase 5: Code Review      → superpowers-requesting-code-review
Phase 6: Finish           → superpowers-finishing-a-development-branch
```

## Prerequisites

- [beads](https://github.com/gastownhall/beads) — issue tracker
- [gitnexus](https://www.npmjs.com/package/gitnexus) — code knowledge graph
- [obra/superpowers](https://github.com/obra/superpowers) — 14 skill modules
- [mattpocock/skills](https://github.com/mattpocock/skills) — TDD skill
- Node.js ≥ 18, Git, Python ≥ 3.10 (for Autoresearch ML mode)

## Install

```bash
# 1. Install prerequisites
npm install -g gitnexus
go install github.com/gastownhall/beads/cmd/bd@latest

# 2. Install superpowers (Claude Code plugin marketplace)
/plugin install superpowers@claude-plugins-official

# 3. Install this skill
#    Copy devflow/ to ~/.claude/skills/devflow/
#    Or clone directly:
git clone https://github.com/TheonePro7/devflow.git ~/.claude/skills/devflow

# 4. Init project
bd init
npx gitnexus analyze --force
```

## Usage

Start a Claude Code session in your project and describe a development task.
The `devflow` skill auto-triggers and routes through the 7-phase pipeline.

## Files

```
devflow/
├── SKILL.md         # Skill definition — phase orchestration
├── prompts/         # Subagent prompt templates
│   ├── implementer-prompt.md
│   ├── spec-reviewer-prompt.md
│   ├── code-quality-reviewer-prompt.md
│   └── code-reviewer-prompt.md
├── README.md
├── LICENSE          # MIT
└── .gitignore
```

## Credits

Built on top of:
- [obra/superpowers](https://github.com/obra/superpowers) — agentic skills framework
- [mattpocock/skills](https://github.com/mattpocock/skills) — TDD & engineering skills
- [beads](https://github.com/gastownhall/beads) — Dolt-backed issue tracker
- [gitnexus](https://github.com/anthropics/gitnexus) — code intelligence graph
