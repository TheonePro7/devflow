#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${CYAN}=== devflow setup (Phase 1) ===${NC}"
echo ""

# ---- Step 1: Check prerequisites ----
MISSING=()

if ! command -v bd &>/dev/null; then
    MISSING+=("beads (bd) — install: go install github.com/gastownhall/beads/cmd/bd@latest")
fi

if ! command -v gitnexus &>/dev/null; then
    MISSING+=("gitnexus — install: npm install -g gitnexus")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}[FAIL] Missing prerequisites:${NC}"
    for m in "${MISSING[@]}"; do
        echo "       $m"
    done
    exit 1
fi

echo -e "${GREEN}[PASS] Prerequisites: beads + gitnexus${NC}"

GITNEXUS_OK=false

# ---- Step 2: Init beads ----
echo ""
echo -e "${YELLOW}--- beads init ---${NC}"
if bd init 2>/dev/null; then
    echo -e "${GREEN}[PASS] beads initialized${NC}"
else
    echo -e "${YELLOW}[WARN] beads init failed (maybe already initialized)${NC}"
fi

# ---- Step 3: GitNexus analyze ----
echo ""
echo -e "${YELLOW}--- gitnexus analyze ---${NC}"
if npx gitnexus analyze . --force 2>&1; then
    GITNEXUS_OK=true
    echo -e "${GREEN}[PASS] gitnexus index built${NC}"
else
    GITNEXUS_OK=false
    echo -e "${YELLOW}[WARN] gitnexus analyze failed (non-fatal)${NC}"
    echo -e "${YELLOW}       Phase 1 continues in degraded mode.${NC}"
    echo -e "${YELLOW}       Workaround: run in native PowerShell: gitnexus analyze . --force${NC}"
fi

# ---- Step 4: Seed docs/CONTEXT.md (if not exists) ----
echo ""
echo -e "${YELLOW}--- seeding project docs ---${NC}"
if [ ! -f docs/CONTEXT.md ]; then
    cat > docs/CONTEXT.md << 'CONTEXTEOF'
# Project Context — Ubiquitous Language

## Project
<!-- TODO: describe what this project does -->

## Domain Glossary
<!-- TODO: add key terms and definitions -->
CONTEXTEOF
    echo -e "${GREEN}[PASS] docs/CONTEXT.md seeded${NC}"
else
    echo -e "${GRAY}[SKIP] docs/CONTEXT.md already exists${NC}"
fi

# ---- Step 5: Seed docs/adr/ (if empty) ----
if [ ! -d docs/adr ]; then
    mkdir -p docs/adr
    cat > docs/adr/README.md << 'ADREOF'
# Architecture Decision Records

## Index

<!-- Add ADRs here sequentially -->
ADREOF
    echo -e "${GREEN}[PASS] docs/adr/ seeded${NC}"
else
    echo -e "${GRAY}[SKIP] docs/adr/ already exists${NC}"
fi

# ---- Step 6: Seed docs/tdd/ (if empty) ----
if [ ! -d docs/tdd ]; then
    mkdir -p docs/tdd
    echo -e "${GREEN}[PASS] docs/tdd/ directory created${NC}"
    echo -e "${GRAY}      (copy reference docs from devflow/docs/tdd/)${NC}"
else
    echo -e "${GRAY}[SKIP] docs/tdd/ already exists${NC}"
fi

# ---- Step 7: Install autoresearch (unless opted out) ----
echo ""
echo -e "${YELLOW}--- autoresearch install ---${NC}"
if [ "${DEVFLOW_NO_AUTORESEARCH:-}" = "1" ]; then
    echo -e "${GRAY}[SKIP] DEVFLOW_NO_AUTORESEARCH is set — skipping${NC}"
else
    if npx skills add uditgoenka/autoresearch 2>/dev/null; then
        echo -e "${GREEN}[PASS] autoresearch installed${NC}"
        echo -e "${GRAY}       Auto-optimization at probe/scenario/fix/security gates.${NC}"
        echo -e "${GRAY}       Disable: export DEVFLOW_NO_AUTORESEARCH=1${NC}"
    else
        echo -e "${YELLOW}[WARN] autoresearch install failed${NC}"
        echo -e "${GRAY}       Run manually: npx skills add uditgoenka/autoresearch${NC}"
    fi
fi

# ---- Step 8: Check git guardrails hook ----
if [ ! -f .claude/hooks/guardrails-git.ps1 ]; then
    echo -e "${YELLOW}[WARN] .claude/hooks/guardrails-git.ps1 not found${NC}"
    echo -e "${GRAY}       Copy from devflow skill directory to enable git safety.${NC}"
else
    echo -e "${GREEN}[PASS] git guardrails hook present${NC}"
fi

# ---- Step 9: Summary ----
echo ""
echo -e "${CYAN}=== devflow ready ===${NC}"
if [ "$GITNEXUS_OK" = "true" ]; then
    echo -e "${GRAY}  phase 1:  beads + gitnexus + docs seeded + guardrails + autoresearch${NC}"
else
    echo -e "${YELLOW}  phase 1:  beads + docs seeded + guardrails + autoresearch (gitnexus: DEGRADED)${NC}"
    echo -e "${GRAY}            fix: run 'gitnexus analyze . --force' in native PowerShell${NC}"
fi
echo -e "${GRAY}  phase 2:  superpowers-* pipeline + grill + 4 autoresearch gates${NC}"
echo -e "${GRAY}            probe(①¾) → scenario(②½) → fix-per-task(③) → security(②¾)${NC}"
echo -e "${GRAY}  opt-out:   export DEVFLOW_NO_AUTORESEARCH=1  (disable all auto gates)${NC}"
echo ""
echo -e "${GREEN}Start a dev task in Claude Code — devflow auto-triggers.${NC}"
