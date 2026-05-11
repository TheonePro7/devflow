#!/usr/bin/env bash
# Initialize devflow scaffold in the current project directory.
# Self-contained — generates all files directly, no repo copy needed.
#
# Creates: .devflow/, .beads/, .gitnexus/, .claude/ (hooks + settings),
#          docs/ (CONTEXT.md, ADR, TDD), .gitignore
#
# Usage:
#   bash setup.sh              # Merge mode (idempotent)
#   bash setup.sh --fresh      # Fresh install (overwrite existing)
#   bash setup.sh --skip-autoresearch

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

FRESH=false
SKIP_AUTORESEARCH=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fresh) FRESH=true; shift ;;
    --skip-autoresearch) SKIP_AUTORESEARCH=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

MERGE_MODE=true
if [ "$FRESH" = true ]; then MERGE_MODE=false; fi

echo -e "${CYAN}=== devflow setup (project scaffold) ===${NC}"
if [ "$MERGE_MODE" = true ]; then
  echo -e "${GRAY}  mode: merge — existing configs will be preserved.${NC}"
else
  echo -e "${YELLOW}  mode: fresh — existing configs will be overwritten.${NC}"
fi
echo ""

# ---- Step 1: Create .devflow/ state directory ----
echo -e "${YELLOW}--- .devflow/ state ---${NC}"
if [ ! -d .devflow ] || [ "$FRESH" = true ]; then
  mkdir -p .devflow
  cat > .devflow/state << 'STATE'
{"phase":1,"step":"","feature":"","prd":"","blocker":"","gate_probe":"pending","gate_scenario":"pending","gate_fix":"pending","gate_security":"pending","updatedAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"}
STATE
  echo -e "${GREEN}[PASS] .devflow/state initialized${NC}"
else
  echo -e "${YELLOW}[SKIP] .devflow/state already exists${NC}"
fi

# ---- Step 2: Init beads ----
echo ""
echo -e "${YELLOW}--- beads init ---${NC}"
if [ -d .beads ] && [ "$MERGE_MODE" = true ]; then
  echo -e "${YELLOW}[SKIP] .beads/ already exists${NC}"
else
  if bd init 2>/dev/null; then
    echo -e "${GREEN}[PASS] beads initialized${NC}"
  else
    echo -e "${YELLOW}[WARN] beads init failed — run 'bd init' manually${NC}"
  fi
fi

# ---- Step 3: GitNexus analyze ----
echo ""
echo -e "${YELLOW}--- gitnexus analyze ---${NC}"
GITNEXUS_OK=false
if [ -d .gitnexus ] && [ "$MERGE_MODE" = true ]; then
  echo -e "${YELLOW}[SKIP] .gitnexus/ already exists${NC}"
  GITNEXUS_OK=true
else
  if docker ps >/dev/null 2>&1; then
    echo -e "${GRAY}[INFO] Docker detected — using gitnexus Docker image...${NC}"
    IMAGE="ghcr.io/abhigyanpatwari/gitnexus:latest"
    if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
      docker pull "$IMAGE" >/dev/null 2>&1
    fi
    REPO="$(pwd)"
    CLI="node /app/gitnexus/dist/cli/index.js"
    if docker run --rm -v "$REPO:/repo" --user root --entrypoint sh "$IMAGE" -c \
         "$CLI analyze /repo --skip-git --force" 2>/dev/null; then
      GITNEXUS_OK=true
      echo -e "${GREEN}[PASS] gitnexus index built (via Docker)${NC}"
    else
      echo -e "${YELLOW}[WARN] gitnexus Docker analyze failed${NC}"
    fi
  else
    echo -e "${YELLOW}[INFO] Docker not detected — gitnexus requires Docker.${NC}"
    echo -e "${GRAY}       Install from: https://docs.docker.com/desktop/setup/install/windows-install/${NC}"
    echo -e "${GRAY}       Skipping gitnexus for now — NON-FATAL.${NC}"
  fi
fi

# ---- Step 4: Create .claude directory ----
echo ""
echo -e "${YELLOW}--- .claude/ structure ---${NC}"
mkdir -p .claude/hooks
echo -e "${GREEN}[PASS] .claude/ + hooks/ created${NC}"

# ---- Step 5: settings.json ----
echo ""
echo -e "${YELLOW}--- settings.json ---${NC}"
SETTINGS_PATH=".claude/settings.json"
if [ -f "$SETTINGS_PATH" ] && [ "$MERGE_MODE" = true ]; then
  echo -e "${YELLOW}[SKIP] settings.json exists (use --fresh to overwrite)${NC}"
else
  cat > "$SETTINGS_PATH" << 'SETTINGSEOF'
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "PowerShell(*)",
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep",
      "Bash(devflow *)",
      "PowerShell(devflow *)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File .claude/hooks/guardrails-git.ps1",
            "shell": "powershell",
            "timeout": 5,
            "statusMessage": "devflow: checking git safety..."
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File .claude/hooks/session-start.ps1"
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
  echo -e "${GREEN}[PASS] settings.json created${NC}"
fi

# ---- Step 6: Guardrails hooks ----
echo ""
echo -e "${YELLOW}--- guardrails hooks ---${NC}"

if [ ! -f .claude/hooks/guardrails-git.ps1 ] || [ "$FRESH" = true ]; then
  cat > .claude/hooks/guardrails-git.ps1 << 'HOOKEOF'
# guardrails-git.ps1 — PreToolUse hook for Bash
$inputJson = [Console]::In.ReadToEnd()
if (-not $inputJson) { return }
try { $payload = $inputJson | ConvertFrom-Json } catch { return }
$command = $payload.tool_input.command
if (-not $command) { return }
$dangerous = @(
    'git push --force', 'git push -f', 'git push origin +',
    'git reset --hard', 'git checkout .', 'git checkout --',
    'git restore .', 'git restore --staged .',
    'git clean -f', 'git clean -fd',
    'git branch -D', 'git rebase -i HEAD',
    'git --no-verify', 'git commit --no-verify'
)
foreach ($pattern in $dangerous) {
    if ($command -match [regex]::Escape($pattern)) {
        @{ action = "reject"; message = "devflow guardrails: blocked dangerous git command: $pattern" } | ConvertTo-Json -Compress
        return
    }
}
HOOKEOF
  echo -e "${GREEN}[PASS] guardrails-git.ps1 installed${NC}"
else
  echo -e "${YELLOW}[SKIP] guardrails-git.ps1 already exists${NC}"
fi

if [ ! -f .claude/hooks/guardrails-git.sh ] || [ "$FRESH" = true ]; then
  cat > .claude/hooks/guardrails-git.sh << 'HOOKEOF'
#!/bin/bash
# guardrails-git.sh — PreToolUse hook for Bash
input=$(cat)
command=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input']['command'])" 2>/dev/null)
[ -z "$command" ] && exit 0
dangerous=(
  'git push --force' 'git push -f' 'git push origin +'
  'git reset --hard' 'git checkout .' 'git checkout --'
  'git restore .' 'git restore --staged .'
  'git clean -f' 'git clean -fd'
  'git branch -D' 'git rebase -i HEAD'
  'git --no-verify' 'git commit --no-verify'
)
for pattern in "${dangerous[@]}"; do
  if [[ "$command" == *"$pattern"* ]]; then
    echo "{\"action\":\"reject\",\"message\":\"devflow guardrails: blocked dangerous git command: $pattern\"}"
    exit 0
  fi
done
HOOKEOF
  chmod +x .claude/hooks/guardrails-git.sh
  echo -e "${GREEN}[PASS] guardrails-git.sh installed${NC}"
else
  echo -e "${YELLOW}[SKIP] guardrails-git.sh already exists${NC}"
fi

# ---- Step 7: Session hook ----
echo ""
echo -e "${YELLOW}--- session hooks ---${NC}"
if [ ! -f .claude/hooks/session-start.ps1 ] || [ "$FRESH" = true ]; then
  cat > .claude/hooks/session-start.ps1 << 'SESSEOF'
# session-start.ps1 — devflow session start hook
Write-Host "devflow: session start" -ForegroundColor Cyan
$stateFile = ".devflow/state"
if (Test-Path $stateFile) {
    try {
        $state = Get-Content $stateFile -Raw -Encoding utf8 | ConvertFrom-Json
        Write-Host "devflow: Phase $($state.phase) | step: $($state.step) | feature: $($state.feature)" -ForegroundColor Cyan
    } catch { }
}
SESSEOF
  echo -e "${GREEN}[PASS] session-start.ps1 installed${NC}"
else
  echo -e "${YELLOW}[SKIP] session-start.ps1 already exists${NC}"
fi

# ---- Step 8: Seed docs/ ----
echo ""
echo -e "${YELLOW}--- seed docs/ ---${NC}"

# Create doc directories
mkdir -p docs/prd docs/ux docs/adr docs/tdd docs/superpowers/specs

# CONTEXT.md
if [ ! -f docs/CONTEXT.md ] || [ "$FRESH" = true ]; then
  cat > docs/CONTEXT.md << 'CONTEXTEOF'
# Project Context

## Project
<!-- TODO: describe what this project does -->

## Domain Glossary
<!-- TODO: add key terms and definitions -->
CONTEXTEOF
  echo -e "${GREEN}[PASS] docs/CONTEXT.md seeded${NC}"
else
  echo -e "${YELLOW}[SKIP] docs/CONTEXT.md already exists${NC}"
fi

# ADR index
if [ ! -f docs/adr/README.md ] || [ "$FRESH" = true ]; then
  cat > docs/adr/README.md << 'ADREOF'
# Architecture Decision Records

## ADR Index

<!-- Add new ADRs below -->
ADREOF
  echo -e "${GREEN}[PASS] docs/adr/ seeded${NC}"
else
  echo -e "${YELLOW}[SKIP] docs/adr/ already exists${NC}"
fi

# TDD philosophy
if [ ! -f docs/tdd/testing-philosophy.md ] || [ "$FRESH" = true ]; then
  cat > docs/tdd/testing-philosophy.md << 'TDDEOF'
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** — tests should verify outcomes, not internals
2. **Write tests before code** — TDD cycle: Red -> Green -> Refactor
3. **One assertion per test** — each test verifies one behavior
4. **Tests are documentation** — a good test suite describes how the system works
TDDEOF
  echo -e "${GREEN}[PASS] docs/tdd/ seeded${NC}"
else
  echo -e "${YELLOW}[SKIP] docs/tdd/ already exists${NC}"
fi

# ---- Step 9: .gitignore ----
echo ""
echo -e "${YELLOW}--- .gitignore ---${NC}"
if [ ! -f .gitignore ] || [ "$FRESH" = true ]; then
  cat > .gitignore << 'GITIGNOREEOF'
# devflow
.devflow/
.beads/
.gitnexus/

# OS
.DS_Store
Thumbs.db

# Python
__pycache__/
*.pyc
*.pyo
.env
.venv/
venv/
GITIGNOREEOF
  echo -e "${GREEN}[PASS] .gitignore created${NC}"
else
  # Append devflow entries if missing
  for entry in ".devflow/" ".beads/" ".gitnexus/"; do
    if ! grep -qF "$entry" .gitignore 2>/dev/null; then
      echo "$entry" >> .gitignore
      ADDED=true
    fi
  done
  if [ "${ADDED:-false}" = true ]; then
    echo -e "${GREEN}[PASS] devflow entries added to .gitignore${NC}"
  else
    echo -e "${YELLOW}[SKIP] .gitignore already has devflow entries${NC}"
  fi
fi

# ---- Step 10: Autoresearch ----
if [ "$SKIP_AUTORESEARCH" = false ]; then
  echo ""
  echo -e "${YELLOW}--- autoresearch ---${NC}"
  if npx --yes skills add uditgoenka/autoresearch --yes --claude 2>/dev/null; then
    echo -e "${GREEN}[PASS] autoresearch installed${NC}"
  else
    echo -e "${YELLOW}[WARN] autoresearch install had issues${NC}"
  fi
fi

# ---- Summary ----
echo ""
echo -e "${CYAN}=== devflow scaffold ready ===${NC}"
echo -e "${GRAY}  .devflow/     state tracking${NC}"
echo -e "${GRAY}  .beads/       issue tracking${NC}"
echo -e "${GRAY}  .gitnexus/    code graph (if Docker available)${NC}"
echo -e "${GRAY}  .claude/      hooks + settings${NC}"
echo -e "${GRAY}  docs/         seed docs${NC}"
echo -e "${GRAY}  .gitignore    devflow entries${NC}"
echo ""
echo -e "${GREEN}Open in Claude Code — devflow guides the pipeline.${NC}"
