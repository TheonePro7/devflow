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
    echo -e "${GREEN}[PASS] gitnexus index built${NC}"
else
    echo -e "${RED}[FAIL] gitnexus analyze failed — run 'npx gitnexus analyze . --force' manually${NC}"
fi

# ---- Step 4: Summary ----
echo ""
echo -e "${CYAN}=== devflow ready ===${NC}"
echo -e "${GRAY}  phase 1:  beads + gitnexus initialized${NC}"
echo -e "${GRAY}  phase 2:  superpowers-* pipeline + tool injection${NC}"
echo -e "${GRAY}  on-demand: /autoresearch (if installed)${NC}"
echo ""
echo -e "${GREEN}Start a dev task in Claude Code — devflow auto-triggers.${NC}"
