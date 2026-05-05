#!/usr/bin/env bash
# Initialize devflow workflow in a project (Phase 1 Setup).
# Auto-installs tools, initializes beads + gitnexus, seeds docs, registers guardrails.
# Supports merge mode (default) — detects and merges existing configs.
#
# Usage:
#   bash setup.sh              # Merge mode (idempotent)
#   bash setup.sh --fresh      # Fresh install (overwrite)
#   bash setup.sh --skip-autoresearch
#   bash setup.sh --with-designer    # Also install optional UI generators

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

FRESH=false
SKIP_AUTORESEARCH=false
WITH_DESIGNER=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fresh) FRESH=true; shift ;;
    --skip-autoresearch) SKIP_AUTORESEARCH=true; shift ;;
    --with-designer) WITH_DESIGNER=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

MERGE_MODE=true
if [ "$FRESH" = true ]; then
  MERGE_MODE=false
fi

echo -e "${CYAN}=== devflow setup (Phase 1) ===${NC}"
if [ "$MERGE_MODE" = true ]; then
  echo -e "${GRAY}  mode: merge (idempotent) — existing configs will be preserved and extended.${NC}"
else
  echo -e "${YELLOW}  mode: fresh — existing configs may be overwritten.${NC}"
fi
echo ""

# ---- Step 1: Check & install prerequisites ----
MISSING=()

if ! command -v bd &>/dev/null; then
  echo -e "${YELLOW}[INFO] beads (bd) not found — auto-installing...${NC}"
  if go install github.com/gastownhall/beads/cmd/bd@latest 2>/dev/null; then
    export PATH="$HOME/go/bin:$PATH"
    if ! command -v bd &>/dev/null; then
      MISSING+=("beads (bd) — installed but not in PATH. Add \$HOME/go/bin to PATH")
    fi
  else
    MISSING+=("beads (bd) — auto-install failed. Manual: go install github.com/gastownhall/beads/cmd/bd@latest")
  fi
fi

if ! command -v gitnexus &>/dev/null; then
  echo -e "${YELLOW}[INFO] gitnexus not found — auto-installing...${NC}"
  if npm install -g gitnexus 2>/dev/null; then
    if ! command -v gitnexus &>/dev/null; then
      MISSING+=("gitnexus — npm install succeeded but command not found. Try: npx gitnexus")
    fi
  else
    MISSING+=("gitnexus — auto-install failed. Manual: npm install -g gitnexus")
  fi
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${RED}[FAIL] Some tools could not be auto-installed:${NC}"
  for m in "${MISSING[@]}"; do echo "       $m"; done
  exit 1
fi
echo -e "${GREEN}[PASS] Prerequisites: beads + gitnexus${NC}"

GITNEXUS_OK=false

# ---- Step 2: Init beads ----
echo ""
echo -e "${YELLOW}--- beads init ---${NC}"
if [ -d .beads ]; then
  echo -e "${YELLOW}[SKIP] .beads/ already exists — running bd doctor to verify...${NC}"
  if bd doctor 2>/dev/null; then
    echo -e "${GREEN}[PASS] beads OK (bd doctor passed)${NC}"
  else
    echo -e "${YELLOW}[WARN] beads issues found${NC}"
  fi
else
  if bd init 2>/dev/null; then
    echo -e "${GREEN}[PASS] beads initialized${NC}"
  else
    echo -e "${YELLOW}[WARN] beads init failed${NC}"
  fi
fi

# ---- Step 3: GitNexus analyze ----
echo ""
echo -e "${YELLOW}--- gitnexus analyze ---${NC}"
if [ -d .gitnexus ]; then
  echo -e "${YELLOW}[SKIP] .gitnexus/ already exists — skipping (use --fresh to rebuild)${NC}"
  GITNEXUS_OK=true
else
  # Try Docker-based gitnexus first (bypasses tree-sitter native module issues)
  if docker ps >/dev/null 2>&1; then
    echo -e "${GRAY}[INFO] Docker detected — using gitnexus Docker image...${NC}"
    IMAGE="ghcr.io/abhigyanpatwari/gitnexus:latest"
    if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
      docker pull "$IMAGE" >/dev/null 2>&1
    fi
    REPO="$(pwd)"
    CLI="node /app/gitnexus/dist/cli/index.js"
    if docker run --rm -v "$REPO:/repo" --entrypoint sh "$IMAGE" -c \
         "$CLI analyze /repo --force" 2>/dev/null; then
      GITNEXUS_OK=true
      echo -e "${GREEN}[PASS] gitnexus index built (via Docker)${NC}"
    else
      echo -e "${YELLOW}[WARN] gitnexus Docker analyze failed — falling back to native${NC}"
    fi
  fi

  # Fall back to native if Docker unavailable or failed
  if [ "$GITNEXUS_OK" != "true" ]; then
    if npx gitnexus analyze . --force 2>/dev/null; then
      GITNEXUS_OK=true
      echo -e "${GREEN}[PASS] gitnexus index built (native)${NC}"
    else
      echo -e "${YELLOW}[WARN] gitnexus analyze failed (non-fatal)${NC}"
    fi
  fi
fi

# ---- Step 4: Settings.json merge ----
echo ""
echo -e "${YELLOW}--- settings.json ---${NC}"
if [ -f scripts/merge-settings.sh ]; then
  bash scripts/merge-settings.sh
fi
echo -e "${GREEN}[PASS] settings.json configured${NC}"

# ---- Step 5: Guardrails hooks ----
echo ""
echo -e "${YELLOW}--- guardrails hooks ---${NC}"
mkdir -p .claude/hooks

# Determine script directory
DEVFLOW_DIR="$(cd "$(dirname "$0")" && pwd)"

# PowerShell guardrails
if [ ! -f .claude/hooks/guardrails-git.ps1 ] || [ "$FRESH" = true ]; then
  if [ -f "$DEVFLOW_DIR/.claude/hooks/guardrails-git.ps1" ]; then
    cp "$DEVFLOW_DIR/.claude/hooks/guardrails-git.ps1" .claude/hooks/guardrails-git.ps1
    echo -e "${GREEN}[PASS] guardrails-git.ps1 installed${NC}"
  fi
else
  if [ -f scripts/merge-guardrails.sh ]; then
    bash scripts/merge-guardrails.sh
  fi
fi

# bash guardrails
if [ ! -f .claude/hooks/guardrails-git.sh ] || [ "$FRESH" = true ]; then
  if [ -f "$DEVFLOW_DIR/.claude/hooks/guardrails-git.sh" ]; then
    cp "$DEVFLOW_DIR/.claude/hooks/guardrails-git.sh" .claude/hooks/guardrails-git.sh
    echo -e "${GREEN}[PASS] guardrails-git.sh installed${NC}"
  fi
fi

# ---- Step 5.5: Create .devflow/ state directory ----
echo ""
echo -e "${YELLOW}--- .devflow/ state directory ---${NC}"
if [ ! -d .devflow ]; then
  mkdir -p .devflow
  echo -e "${GREEN}[PASS] .devflow/ created${NC}"
else
  echo -e "${YELLOW}[SKIP] .devflow/ already exists${NC}"
fi
if [ ! -f .devflow/state ]; then
  cat > .devflow/state << 'STATE'
{"phase":0,"step":"","feature":"","prd":"","blocker":"","updatedAt":"2026-05-05T00:00:00Z"}
STATE
  echo -e "${GREEN}[PASS] .devflow/state initialized${NC}"
else
  echo -e "${YELLOW}[SKIP] .devflow/state already exists${NC}"
fi

# ---- Step 6: Seed docs/ with merge ----
echo ""
echo -e "${YELLOW}--- seeding docs/ ---${NC}"

# CONTEXT.md
if [ ! -f docs/CONTEXT.md ]; then
  cat > docs/CONTEXT.md << 'CONTEXTEOF'
# Project Context - Ubiquitous Language

## Project
<!-- TODO: describe what this project does -->

## Domain Glossary
<!-- TODO: add key terms and definitions -->
CONTEXTEOF
  echo -e "${GREEN}[PASS] docs/CONTEXT.md seeded${NC}"
elif [ "$MERGE_MODE" = true ] && [ -f scripts/merge-docs.sh ]; then
  bash scripts/merge-docs.sh
fi

# ADR
if [ ! -d docs/adr ]; then
  mkdir -p docs/adr
  cat > docs/adr/README.md << 'ADREOF'
# Architecture Decision Records

Each ADR (Architecture Decision Record) captures a decision:
- **Context** - what problem or constraint drove the decision
- **Decision** - what was chosen and why alternatives were rejected
- **Consequences** - what tradeoffs, migrations, or follow-up work result

## ADR Index

<!-- Add new ADRs below -->
ADREOF
  echo -e "${GREEN}[PASS] docs/adr/ seeded${NC}"
elif [ "$MERGE_MODE" = true ] && [ -f scripts/merge-docs.sh ]; then
  bash scripts/merge-docs.sh
fi

# TDD
if [ ! -d docs/tdd ]; then
  mkdir -p docs/tdd
  cat > docs/tdd/testing-philosophy.md << 'TDDEOF'
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** - tests should verify outcomes, not internal details
2. **Write tests before code** - TDD cycle: Red -> Green -> Refactor
3. **One assertion per test** - each test should verify one behavior
4. **Tests are documentation** - a good test suite describes how the system works

## Coverage Goals

- Unit tests: 90%+ coverage on business logic
- Integration tests: critical paths only
- E2E tests: happy path + top 3 error scenarios
TDDEOF
  echo -e "${GREEN}[PASS] docs/tdd/ seeded${NC}"
elif [ -d docs/tdd ] && [ "$(find docs/tdd -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)" -eq 0 ]; then
  # Directory exists but empty - seed it anyway
  cat > docs/tdd/testing-philosophy.md << 'TDDEOF'
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** - tests should verify outcomes, not internal details
2. **Write tests before code** - TDD cycle: Red -> Green -> Refactor
3. **One assertion per test** - each test should verify one behavior
4. **Tests are documentation** - a good test suite describes how the system works

## Coverage Goals

- Unit tests: 90%+ coverage on business logic
- Integration tests: critical paths only
- E2E tests: happy path + top 3 error scenarios
TDDEOF
  echo -e "${GREEN}[PASS] docs/tdd/ seeded${NC}"
elif [ -d docs/tdd ]; then
  echo -e "${YELLOW}[SKIP] docs/tdd/ already has content — user modifications respected${NC}"
fi

# ---- Step 7: .gitignore merge ----
echo ""
echo -e "${YELLOW}--- .gitignore ---${NC}"
if [ -f scripts/merge-gitignore.sh ]; then
  bash scripts/merge-gitignore.sh
fi

# ---- Step 8: Install autoresearch (unless opted out) ----
if [ "$SKIP_AUTORESEARCH" = true ] || [ "${DEVFLOW_NO_AUTORESEARCH:-}" = "1" ]; then
  echo ""
  echo -e "${YELLOW}--- autoresearch ---${NC}"
  echo -e "${GRAY}[SKIP] opted out via flag or DEVFLOW_NO_AUTORESEARCH env var${NC}"
else
  echo ""
  echo -e "${YELLOW}--- autoresearch install ---${NC}"
  if npx skills add uditgoenka/autoresearch 2>/dev/null; then
    echo -e "${GREEN}[PASS] autoresearch installed${NC}"
    echo -e "${GRAY}       Auto-optimization at probe/scenario/fix/security gates.${NC}"
    echo -e "${GRAY}       Disable: export DEVFLOW_NO_AUTORESEARCH=1${NC}"
  else
    echo -e "${YELLOW}[WARN] autoresearch install failed${NC}"
    echo -e "${GRAY}       Run manually: npx skills add uditgoenka/autoresearch${NC}"
  fi
fi

# ---- Optional: Auto-Designer generators ----
if [ "$WITH_DESIGNER" = true ]; then
  echo ""
  echo -e "${YELLOW}--- auto-designer generators ---${NC}"
  echo -e "${GRAY}  Installing optional UI generation tools...${NC}"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "$SCRIPT_DIR/scripts/auto-designer.sh" --install openui 2>/dev/null || echo -e "${YELLOW}  [SKIP] OpenUI install skipped (install manually: pip install openui)${NC}"
  echo -e "${GREEN}[PASS] auto-designer generators ready${NC}"
fi

# ---- Step 9: Superpowers check ----
echo ""
echo -e "${YELLOW}--- superpowers check ---${NC}"
if [ -f scripts/check-superpowers.sh ]; then
  bash scripts/check-superpowers.sh --quiet
fi

# ---- Step 10: Summary ----
echo ""
echo -e "${CYAN}=== devflow ready ===${NC}"
if [ "$GITNEXUS_OK" = true ]; then
  echo -e "${GRAY}  phase 1:  beads + gitnexus + docs + guardrails + autoresearch + merge helpers${NC}"
else
  echo -e "${YELLOW}  phase 1:  beads + docs + guardrails + autoresearch (gitnexus: DEGRADED)${NC}"
fi
echo -e "${GRAY}  scripts:   merge-settings, merge-guardrails, merge-gitignore, merge-docs, check-superpowers${NC}"
echo -e "${GRAY}  merge:     existing configs detected and extended (default mode)${NC}"
echo -e "${GRAY}  phase 2:   superpowers-* pipeline + grill + 4 autoresearch gates${NC}"
echo -e "${GRAY}  opt-out:   export DEVFLOW_NO_AUTORESEARCH=1  (disable all auto gates)${NC}"
echo ""
echo -e "${GREEN}Start a dev task in Claude Code — devflow auto-triggers.${NC}"
