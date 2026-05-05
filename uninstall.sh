#!/usr/bin/env bash
# Uninstall devflow components with tiered safety.
#
# Tiers:
#   1. Safe (auto): --hooks, --guardrails, --skill, --autoresearch
#   2. Ask (interactive): --docs (prints removal instructions)
#   3. Warn (--force required): --beads, --gitnexus (data loss risk)
#
# Usage:
#   bash uninstall.sh --hooks --guardrails
#   bash uninstall.sh --all
#   bash uninstall.sh --all --force

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

HOOKS=false
GUARDRAILS=false
SKILL=false
AUTORESEARCH=false
DOCS=false
BEADS=false
GITNEXUS=false
ALL=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hooks) HOOKS=true; shift ;;
    --guardrails) GUARDRAILS=true; shift ;;
    --skill) SKILL=true; shift ;;
    --autoresearch) AUTORESEARCH=true; shift ;;
    --docs) DOCS=true; shift ;;
    --beads) BEADS=true; shift ;;
    --gitnexus) GITNEXUS=true; shift ;;
    --all) ALL=true; shift ;;
    --force) FORCE=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ "$ALL" = true ]; then
  HOOKS=true
  GUARDRAILS=true
  SKILL=true
  AUTORESEARCH=true
  DOCS=true
  if [ "$FORCE" = true ]; then
    BEADS=true
    GITNEXUS=true
  fi
fi

DEVFLOW_DIR="${HOME:-~}/.claude/skills/devflow"

echo -e "${CYAN}=== devflow uninstall ===${NC}"
echo ""

# ---- Tier 1: Safe (auto) ----

# --hooks: Remove devflow hooks from settings.json
if [ "$HOOKS" = true ]; then
  echo -e "${YELLOW}--- hooks ---${NC}"
  if [ -f .claude/settings.json ]; then
    cp .claude/settings.json .claude/settings.json.uninstall-bak
    echo -e "${GRAY}[BAK] Backed up to .claude/settings.json.uninstall-bak${NC}"

    # Use jq to remove devflow-specific hooks if available
    if command -v jq &>/dev/null; then
      # Remove hook entries containing devflow commands
      jq '
        if .hooks then
          .hooks |= with_entries(
            .value |= map(
              select(
                [.hooks[]?.command] | any(
                  . // "" | contains("guardrails-git") or
                  contains("devflow-init-check") or
                  contains("bd prime")
                ) | not
              )
            )
          )
        else . end
      ' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
      echo -e "${GREEN}[OK] Devflow hooks removed from settings.json${NC}"
    else
      echo -e "${YELLOW}[SKIP] jq required to edit settings.json. Manual:${NC}"
      echo -e "${GRAY}       Remove devflow hooks from .claude/settings.json manually${NC}"
    fi
  else
    echo -e "${YELLOW}[SKIP] settings.json not found${NC}"
  fi
fi

# --guardrails: Remove guardrails hook scripts
if [ "$GUARDRAILS" = true ]; then
  echo ""
  echo -e "${YELLOW}--- guardrails ---${NC}"
  for f in .claude/hooks/guardrails-git.ps1 .claude/hooks/guardrails-git.sh; do
    if [ -f "$f" ]; then
      rm -f "$f"
      echo -e "${GREEN}[OK] Removed $f${NC}"
    else
      echo -e "${YELLOW}[SKIP] $f not found${NC}"
    fi
  done
fi

# --skill: Remove devflow from ~/.claude/skills/
if [ "$SKILL" = true ]; then
  echo ""
  echo -e "${YELLOW}--- devflow skill ---${NC}"
  if [ -d "$DEVFLOW_DIR" ]; then
    rm -rf "$DEVFLOW_DIR"
    echo -e "${GREEN}[OK] Removed $DEVFLOW_DIR${NC}"
  else
    echo -e "${YELLOW}[SKIP] devflow not found at $DEVFLOW_DIR${NC}"
  fi
fi

# --autoresearch: Remove autoresearch skill
if [ "$AUTORESEARCH" = true ]; then
  echo ""
  echo -e "${YELLOW}--- autoresearch ---${NC}"
  AR_DIR="${HOME:-~}/.claude/skills/autoresearch"
  if [ -d "$AR_DIR" ]; then
    rm -rf "$AR_DIR"
    echo -e "${GREEN}[OK] Removed autoresearch skill${NC}"
  else
    echo -e "${YELLOW}[SKIP] autoresearch not found${NC}"
  fi
  if command -v npx &>/dev/null; then
    npx skills remove uditgoenka/autoresearch 2>/dev/null || true
    echo -e "${GREEN}[OK] Removed autoresearch from skills registry${NC}"
  fi
fi

# ---- Tier 2: Ask (interactive) ----
if [ "$DOCS" = true ]; then
  echo ""
  echo -e "${YELLOW}--- docs ---${NC}"
  for d in docs/tdd docs/superpowers; do
    if [ -d "$d" ]; then
      echo -e "${YELLOW}[WARN] $d/ was created or modified by devflow.${NC}"
      echo -e "${GRAY}       Run: rm -rf $d${NC}"
    else
      echo -e "${YELLOW}[SKIP] $d/ not found${NC}"
    fi
  done
fi

# ---- Tier 3: Warn (--force required) ----
if [ "$BEADS" = true ]; then
  echo ""
  echo -e "${YELLOW}--- beads data ---${NC}"
  if [ -d .beads ]; then
    if [ "$FORCE" = true ]; then
      rm -rf .beads
      echo -e "${GREEN}[OK] Removed .beads/${NC}"
    else
      echo -e "${RED}[WARN] .beads/ contains issue tracking data.${NC}"
      echo -e "${RED}       This will DELETE all issues permanently.${NC}"
      echo -e "${CYAN}       Use --force to confirm data loss acceptance.${NC}"
    fi
  else
    echo -e "${YELLOW}[SKIP] .beads/ not found${NC}"
  fi
fi

if [ "$GITNEXUS" = true ]; then
  echo ""
  echo -e "${YELLOW}--- gitnexus data ---${NC}"
  if [ -d .gitnexus ]; then
    if [ "$FORCE" = true ]; then
      rm -rf .gitnexus
      echo -e "${GREEN}[OK] Removed .gitnexus/${NC}"
    else
      echo -e "${RED}[WARN] .gitnexus/ contains code knowledge graph index.${NC}"
      echo -e "${RED}       This will DELETE all indexed data permanently.${NC}"
      echo -e "${CYAN}       Use --force to confirm data loss acceptance.${NC}"
    fi
  else
    echo -e "${YELLOW}[SKIP] .gitnexus/ not found${NC}"
  fi
fi

echo ""
echo -e "${CYAN}=== uninstall complete ===${NC}"
