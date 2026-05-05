#!/usr/bin/env bash
# prd-to-beads.sh
# Parses a design doc markdown and creates beads issues for each task.
#
# Usage:
#   bash scripts/prd-to-beads.sh -d ./docs/superpowers/specs/my-design.md \
#     -e "My Feature" [-i bd-epic-id]
#
# Looks for "## Task: <title>" headings and optional "Depends on: <id>" lines.

set -euo pipefail

DESIGN_DOC=""
EPIC_TITLE=""
EPIC_ID=""

while getopts "d:e:i:" opt; do
    case $opt in
        d) DESIGN_DOC="$OPTARG" ;;
        e) EPIC_TITLE="$OPTARG" ;;
        i) EPIC_ID="$OPTARG" ;;
        *) echo "Usage: $0 -d <design-doc> -e <epic-title> [-i <epic-id>]"; exit 1 ;;
    esac
done

if [ -z "$DESIGN_DOC" ] || [ -z "$EPIC_TITLE" ]; then
    echo "Usage: $0 -d <design-doc> -e <epic-title> [-i <epic-id>]"
    exit 1
fi

if [ ! -f "$DESIGN_DOC" ]; then
    echo "[ERROR] Design doc not found: $DESIGN_DOC"
    exit 1
fi

if ! command -v bd &>/dev/null; then
    echo "[ERROR] beads (bd) not found — install: go install github.com/gastownhall/beads/cmd/bd@latest"
    exit 1
fi

# Step 1: Create epic if needed
if [ -z "$EPIC_ID" ]; then
    echo "[beads] Creating epic: $EPIC_TITLE"
    EPIC_OUTPUT=$(bd create --title="$EPIC_TITLE" --type=epic 2>&1)
    EPIC_ID=$(echo "$EPIC_OUTPUT" | grep -oE 'bd-[a-z0-9]+' | head -1)
    if [ -z "$EPIC_ID" ]; then
        echo "[WARN] Could not parse epic ID: $EPIC_OUTPUT"
        EPIC_ID="$EPIC_OUTPUT"
    fi
    echo "[OK] Epic ID: $EPIC_ID"
fi

# Step 2: Extract tasks
TASKS=$(grep -nE '^## Task: ' "$DESIGN_DOC" || true)
if [ -z "$TASKS" ]; then
    echo "[WARN] No '## Task:' headings found in $DESIGN_DOC"
    exit 0
fi

echo "$TASKS" | while IFS=: read -r LINE_NUM RAW_TITLE; do
    TITLE="${RAW_TITLE##\#\# Task: }"
    TITLE="${TITLE#"${TITLE%%[![:space:]]*}"}" # trim leading
    TITLE="${TITLE%"${TITLE##*[![:space:]]}"}" # trim trailing

    echo "[beads] Creating task: $TITLE"
    OUTPUT=$(bd create --title="$TITLE" --parent="$EPIC_ID" --type=task 2>&1)
    TASK_ID=$(echo "$OUTPUT" | grep -oE 'bd-[a-z0-9]+\.[0-9]+' | head -1)
    [ -z "$TASK_ID" ] && TASK_ID="$OUTPUT"
    echo "  -> $TASK_ID"

    # Check for "Depends on:" in the next 5 lines after the task heading
    tail -n +$((LINE_NUM + 1)) "$DESIGN_DOC" | head -5 | while IFS= read -r dep_line; do
        DEP=$(echo "$dep_line" | grep -oE '^Depends on: .+' || true)
        if [ -n "$DEP" ]; then
            DEP_ID="${DEP#Depends on: }"
            echo "[beads] Adding dep: $TASK_ID -> $DEP_ID"
            bd dep add "$TASK_ID" "$DEP_ID" 2>/dev/null || true
        fi
    done
done

echo ""
echo "[DONE] Tasks created under epic $EPIC_ID"
