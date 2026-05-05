# devflow Dogfooding: Phase 1 Stability & Cross-Platform Fixes

## Problem Statement

Running devflow on its own repository revealed 4 critical issues that block
the core user experience, particularly on Windows environments.

## Issues Found

### Issue 1: GitNexus SIGSEGV on Windows/bash

- **Severity**: Critical (blocks Phase 1 completion)
- **Symptom**: `gitnexus analyze . --force` exits with code 139 (SIGSEGV)
- **Root cause**: Tree-sitter native module crashes in bash-on-Windows context
- **Impact**: Phase 1 cannot complete; gitnexus code context unavailable to subagents
- **Attempted fixes**: `--verbose`, `--max-file-size 128`, `GITNEXUS_NO_GITIGNORE=1`,
  `--skip-agents-md`, direct node invocation, PowerShell wrapper — ALL segfault
- **Conclusion**: Upstream bug in gitnexus tree-sitter binding on Windows/Node 22.
  Not fixable from devflow side.

### Issue 2: setup.ps1 Not Callable from Bash

- **Severity**: Medium (poor UX)
- **Symptom**: `.\setup.ps1` fails with path error when called from bash
- **Root cause**: Backslash paths and PowerShell-only syntax
- **Impact**: Users on Windows using bash (Git Bash, WSL) get confusing errors

### Issue 3: guardrails-git.ps1 Raw Text Output

- **Severity**: Low (cosmetic)
- **Symptom**: Hook outputs raw string instead of structured JSON on block
- **Root cause**: Missing `ConvertTo-Json` when outputting error message
- **Impact**: Hook system shows error, but still blocks correctly

### Issue 4: beads Auto-Adds Hooks to settings.json

- **Severity**: Low (documentation gap)
- **Symptom**: `bd init` auto-added `bd prime` PreCompact + SessionStart hooks
- **Root cause**: beads default behavior (confirmed: `bd init` uses `--agents-profile`
  flag; `--skip-agents` and `--skip-hooks` exist to disable)
- **Impact**: Settings drift; user unaware of added hooks. devflow should document
  and possibly leverage `bd prime` intentionally.

## Grill Findings and Corrections

Performed plan-grill on initial design. Corrections applied:

1. **CONTEXT.md was empty** — now populated with domain terms (see below).
2. **ADR conflict**: Initial design proposed making gitnexus failure "non-fatal,"
   which contradicts ADR-0001's Phase 1 = "beads + gitnexus initialized."
   Resolution: Accept tradeoff — Phase 1 completes with degraded gitnexus status.
   ADR will be updated to note this exception.
3. **`--lightweight` flag doesn't exist** in gitnexus — removed from solution.
   Verified with --help: no such option.
4. **beads `--skip-hooks` confirmed** — documented. Not a bug, expected behavior.
5. **setup.sh needs same fix** — added to scope.

## Updated Proposed Solutions

### A. GitNexus: Graceful Degradation

1. setup.ps1: catch gitnexus failure, emit clear warning + workaround instructions
2. SKILL.md: document Phase 1 partial completion (beads OK, gitnexus degraded)
3. Provide manual workaround: `npx gitnexus analyze . --force` in native PowerShell
4. Add note that gitnexus SIGSEGV is a known upstream issue on Windows/Node 22

### B. Setup Scripts: Cross-Platform Robustness

1. setup.ps1: detect if called from bash, use absolute paths
2. setup.sh: add same docs seeding logic (currently missing)
3. Both scripts: consistent error messages with actionable next steps

### C. Guardrails: Clean JSON Output

1. Ensure all output paths in guardrails-git.ps1 use ConvertTo-Json
2. Include hookEventName in ALL JSON outputs (success + block paths)

### D. beads Hook Documentation

1. Add beadss `--skip-hooks` / `--skip-agents` to devflow docs
2. Document that `bd init` may modify .claude/settings.json
3. Consider adopting `bd prime` as intentional Phase 3 step

## Scope

- Task 1: Fix gitnexus graceful degradation in setup.ps1 + SKILL.md + ADR
- Task 2: Fix setup.sh (add docs seeding + gitnexus graceful degradation)
- Task 3: Fix guardrails-git.ps1 JSON output
- Task 4: Update CONTEXT.md + ADR for beads hooks documentation

## Out of Scope

- Fixing gitnexus segfault itself (upstream issue)
- Adding Unix guardrails (bash version)
- Migrating hooks to bash equivalents
