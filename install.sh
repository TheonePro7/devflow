#!/usr/bin/env bash
# One-command devflow installer for a project.
# Installs tools (beads, gitnexus, autoresearch) and runs devflow init.
# No repo cloning — devflow CLI is expected to be installed globally.
#
# Usage:
#   cd your-project
#   bash /path/to/devflow/install.sh
#   bash /path/to/devflow/install.sh --offline
#   bash /path/to/devflow/install.sh --skip-autoresearch

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

OFFLINE=false
SKIP_AUTORESEARCH=false
DEVFLOW_SRC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline) OFFLINE=true; shift ;;
    --skip-autoresearch) SKIP_AUTORESEARCH=true; shift ;;
    --devflow-src) DEVFLOW_SRC="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo -e "${CYAN}=== devflow project installer ===${NC}"
echo ""

# ---- Step 1: Check base dependencies ----
echo -e "${YELLOW}--- checking base dependencies ---${NC}"
BASE_MISSING=()

if ! command -v go &>/dev/null; then
  BASE_MISSING+=("Go (https://go.dev/dl/)")
fi
if ! command -v node &>/dev/null; then
  BASE_MISSING+=("Node.js >= 18 (https://nodejs.org/)")
fi
if ! command -v git &>/dev/null; then
  BASE_MISSING+=("Git (https://git-scm.com/)")
fi

if [ ${#BASE_MISSING[@]} -gt 0 ]; then
  echo -e "${YELLOW}[MISS] Base dependencies not found:${NC}"
  for m in "${BASE_MISSING[@]}"; do echo "       $m"; done
  echo ""
  echo -e "${CYAN}       Install these first, then re-run this installer.${NC}"
  exit 1
fi
echo -e "${GREEN}[PASS] Go + Node.js + Git${NC}"

# ---- Step 2: Locate devflow CLI ----
echo ""
echo -e "${YELLOW}--- devflow CLI ---${NC}"
DEVFLOW_CMD=""

if [ -n "$DEVFLOW_SRC" ]; then
  DEVFLOW_CMD="python -m devflow.cli.main"
  export PYTHONPATH="$DEVFLOW_SRC"
  echo -e "${GRAY}[INFO] Using devflow source: $DEVFLOW_SRC${NC}"
elif command -v devflow &>/dev/null; then
  DEVFLOW_CMD="devflow"
  echo -e "${GREEN}[PASS] devflow CLI found in PATH${NC}"
else
  if python -c "import devflow; print('ok')" 2>/dev/null; then
    DEVFLOW_CMD="python -m devflow.cli.main"
    echo -e "${GREEN}[PASS] devflow found via python -m${NC}"
  fi
fi

if [ -z "$DEVFLOW_CMD" ]; then
  echo -e "${YELLOW}[INFO] devflow CLI not found. Install with:${NC}"
  echo -e "${CYAN}       pip install devflow${NC}"
  echo -e "${YELLOW}       Continuing with tool installation only (run devflow init later)...${NC}"
fi

# ---- Step 3: Install beads ----
echo ""
echo -e "${YELLOW}--- beads ---${NC}"
BEADS_OK=false

if [ "$OFFLINE" = false ]; then
  if ! command -v bd &>/dev/null; then
    echo -e "${YELLOW}[INFO] beads (bd) not found - installing via go...${NC}"
    if go install github.com/gastownhall/beads/cmd/bd@latest 2>&1; then
      echo -e "${GREEN}[PASS] beads installed${NC}"
      BEADS_OK=true
    else
      echo -e "${RED}[FAIL] go install beads failed${NC}"
    fi
  else
    echo -e "${GREEN}[PASS] beads already installed${NC}"
    BEADS_OK=true
  fi
else
  BEADS_OK=$(command -v bd &>/dev/null && echo true || echo false)
  echo -e "${YELLOW}[SKIP] Offline mode - beads: $( [ "$BEADS_OK" = true ] && echo 'found' || echo 'missing' )${NC}"
fi

# ---- Step 4: Install gitnexus ----
echo ""
echo -e "${YELLOW}--- gitnexus ---${NC}"
GITNEXUS_OK=false

if [ "$OFFLINE" = false ]; then
  if ! command -v gitnexus &>/dev/null; then
    echo -e "${YELLOW}[INFO] gitnexus not found - installing via npm...${NC}"
    if npm install -g gitnexus 2>&1; then
      echo -e "${GREEN}[PASS] gitnexus installed${NC}"
      GITNEXUS_OK=true
    else
      echo -e "${RED}[FAIL] npm install gitnexus failed${NC}"
    fi
  else
    echo -e "${GREEN}[PASS] gitnexus already installed${NC}"
    GITNEXUS_OK=true
  fi
else
  GITNEXUS_OK=$(command -v gitnexus &>/dev/null && echo true || echo false)
  echo -e "${YELLOW}[SKIP] Offline mode - gitnexus: $( [ "$GITNEXUS_OK" = true ] && echo 'found' || echo 'missing' )${NC}"
fi

# ---- Step 5: Install autoresearch ----
if [ "$SKIP_AUTORESEARCH" = false ]; then
  echo ""
  echo -e "${YELLOW}--- autoresearch ---${NC}"
  if [ "$OFFLINE" = false ]; then
    if npx --yes skills add uditgoenka/autoresearch --yes --claude 2>&1; then
      echo -e "${GREEN}[PASS] autoresearch installed${NC}"
    else
      echo -e "${YELLOW}[WARN] autoresearch install had issues${NC}"
      echo -e "${GRAY}       Run manually: npx skills add uditgoenka/autoresearch${NC}"
    fi
  else
    echo -e "${YELLOW}[SKIP] Offline mode - skip autoresearch install${NC}"
  fi
fi

# ---- Step 6: Run devflow init ----
echo ""
echo -e "${YELLOW}--- project scaffold ---${NC}"

if [ -n "$DEVFLOW_CMD" ]; then
  INIT_CMD="$DEVFLOW_CMD init"
  if [ "$OFFLINE" = true ]; then INIT_CMD="$INIT_CMD --offline"; fi
  if eval "$INIT_CMD"; then
    echo -e "${GREEN}[PASS] devflow init complete${NC}"
  else
    echo -e "${YELLOW}[WARN] devflow init had issues${NC}"
  fi
else
  echo -e "${YELLOW}[INFO] devflow CLI not available - scaffold manually:${NC}"
  echo -e "${CYAN}       1. Install: pip install devflow${NC}"
  echo -e "${CYAN}       2. Init:    devflow init${NC}"
fi

# ---- Step 7: Summary ----
echo ""
echo -e "${CYAN}=== install complete ===${NC}"
echo -e "${GRAY}  beads:       $( [ "$BEADS_OK" = true ] && echo 'installed' || echo 'missing' )${NC}"
echo -e "${GRAY}  gitnexus:    $( [ "$GITNEXUS_OK" = true ] && echo 'installed' || echo 'missing' )${NC}"
echo -e "${GRAY}  autoresearch: $( [ "$SKIP_AUTORESEARCH" = true ] && echo 'skipped' || echo 'attempted' )${NC}"
if [ -n "$DEVFLOW_CMD" ]; then
  echo -e "${GRAY}  scaffold:    init complete${NC}"
else
  echo -e "${YELLOW}  scaffold:    run 'devflow init' after installing CLI${NC}"
fi
echo ""
echo -e "${GREEN}Open this project in Claude Code — devflow guides the pipeline.${NC}"
