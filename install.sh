#!/usr/bin/env bash
# One-command devflow installer with merge-mode setup.
# Checks prerequisites, clones devflow if missing, installs tools,
# runs setup with merge-mode flag.
#
# Usage:
#   cd your-project
#   bash /path/to/devflow/install.sh
#   bash /path/to/devflow/install.sh --offline
#   GIT_PROXY=http://proxy:8080 bash /path/to/devflow/install.sh
#
# After install, in Claude Code run:
#   /plugin install superpowers@claude-plugins-official

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Configuration
DEVFLOW_DIR="${DEVFLOW_DIR:-$HOME/.claude/skills/devflow}"
DEVFLOW_REPO="${DEVFLOW_REPO:-https://github.com/TheonePro7/devflow.git}"
GIT_PROXY="${GIT_PROXY:-}"
OFFLINE=false
SKIP_AUTORESEARCH=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline) OFFLINE=true; shift ;;
    --skip-autoresearch) SKIP_AUTORESEARCH=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo -e "${CYAN}=== devflow installer ===${NC}"
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

# ---- Step 2: Clone devflow (unless offline) ----
echo ""
echo -e "${YELLOW}--- devflow skill ---${NC}"

if [ "$OFFLINE" = true ]; then
  if [ ! -d "$DEVFLOW_DIR" ]; then
    echo -e "${RED}[FAIL] --offline mode but devflow not found at:${NC}"
    echo -e "${RED}       $DEVFLOW_DIR${NC}"
    echo -e "${YELLOW}       Clone manually first:${NC}"
    echo -e "${CYAN}       git clone $DEVFLOW_REPO \"$DEVFLOW_DIR\"${NC}"
    exit 1
  fi
  echo -e "${YELLOW}[SKIP] Offline mode — using existing $DEVFLOW_DIR${NC}"
elif [ -f "$DEVFLOW_DIR/setup.sh" ]; then
  echo -e "${YELLOW}[SKIP] devflow already installed at $DEVFLOW_DIR${NC}"
else
  echo -e "${YELLOW}[INFO] Cloning devflow to $DEVFLOW_DIR ...${NC}"
  mkdir -p "$(dirname "$DEVFLOW_DIR")"

  GIT_ARGS=()
  if [ -n "$GIT_PROXY" ]; then
    GIT_ARGS+=(--config "http.proxy=$GIT_PROXY")
    echo -e "${GRAY}       Using proxy: $GIT_PROXY${NC}"
  fi

  if git clone "${GIT_ARGS[@]}" "$DEVFLOW_REPO" "$DEVFLOW_DIR"; then
    echo -e "${GREEN}[PASS] devflow cloned${NC}"
  else
    echo -e "${RED}[FAIL] Could not clone devflow${NC}"
    echo -e "${CYAN}       Clone manually: git clone $DEVFLOW_REPO \"$DEVFLOW_DIR\"${NC}"
    exit 1
  fi
fi

# ---- Step 3: Superpowers check ----
echo ""
echo -e "${YELLOW}--- superpowers plugin ---${NC}"
if [ -f "$DEVFLOW_DIR/scripts/check-superpowers.sh" ]; then
  bash "$DEVFLOW_DIR/scripts/check-superpowers.sh" || true
else
  echo -e "${YELLOW}[INFO] Run in Claude Code to complete setup:${NC}"
  echo -e "${CYAN}       /plugin install superpowers@claude-plugins-official${NC}"
fi

# ---- Step 4: Run setup ----
echo ""
echo -e "${YELLOW}--- running setup ---${NC}"
SETUP_SCRIPT="$DEVFLOW_DIR/setup.sh"
if [ -f "$SETUP_SCRIPT" ]; then
  SETUP_ARGS=()
  if [ "$SKIP_AUTORESEARCH" = true ]; then
    SETUP_ARGS+=(--skip-autoresearch)
  fi
  bash "$SETUP_SCRIPT" "${SETUP_ARGS[@]}"
else
  echo -e "${RED}[FAIL] setup.sh not found at $SETUP_SCRIPT${NC}"
  exit 1
fi

# ---- Step 5: Post-install instructions ----
echo ""
echo -e "${CYAN}=== Install complete ===${NC}"
echo -e "${GRAY}  devflow installed at: $DEVFLOW_DIR${NC}"
echo -e "${GRAY}  To complete setup, open this project in Claude Code and:${NC}"
echo -e "${GRAY}  1. Claude Code will auto-detect Phase 1 and finalize setup${NC}"
echo -e "${CYAN}  2. If superpowers is missing, type: /plugin install superpowers@claude-plugins-official${NC}"
echo -e "${GRAY}  3. Start a development task — devflow guides the pipeline${NC}"
echo ""
echo -e "${GREEN}Happy coding!${NC}"
