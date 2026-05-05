#!/usr/bin/env bash
# check-superpowers.sh
# Check if superpowers plugin is fully installed.
# Exit codes: 0 = all present, 1 = some missing
#
# Usage:
#   bash scripts/check-superpowers.sh
#   bash scripts/check-superpowers.sh --quiet

set -euo pipefail

QUIET=false
if [[ "${1:-}" == "--quiet" ]]; then
  QUIET=true
fi

HOME_DIR="${HOME:-~}"

SUPERPOWERS_SKILLS=(
  "superpowers-brainstorming"
  "superpowers-writing-plans"
  "superpowers-using-git-worktrees"
  "superpowers-subagent-driven-development"
  "superpowers-requesting-code-review"
  "superpowers-finishing-a-development-branch"
  "superpowers-test-driven-development"
)

ALL_PRESENT=true
PRESENT_COUNT=0
MISSING_COUNT=0

for skill in "${SUPERPOWERS_SKILLS[@]}"; do
  skill_path="$HOME_DIR/.claude/skills/$skill"
  if [ -d "$skill_path" ]; then
    PRESENT_COUNT=$((PRESENT_COUNT + 1))
    if [ "$QUIET" = false ]; then
      echo "[OK] $skill"
    fi
  else
    MISSING_COUNT=$((MISSING_COUNT + 1))
    ALL_PRESENT=false
    echo "[MISS] $skill"
  fi
done

if [ "$ALL_PRESENT" = true ]; then
  if [ "$QUIET" = false ]; then
    echo "[OK] All $PRESENT_COUNT superpowers skills present."
  fi
  exit 0
else
  echo ""
  echo "[WARN] superpowers plugin not fully installed ($MISSING_COUNT missing)."
  echo "       Phase 2 requires superpowers. Run in Claude Code:"
  echo "       /plugin install superpowers@claude-plugins-official"
  exit 1
fi
