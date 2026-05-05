#!/usr/bin/env bash
# devflow-phase-check.sh
# PreToolUse hook for Edit|Write — checks devflow phase before code changes.
set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
STATE_FILE="$PROJECT_ROOT/.devflow/state"

if [ ! -f "$STATE_FILE" ]; then
    cat <<'JSON'
{"systemMessage": "⚙️ devflow: .devflow/state 不存在，请先运行 setup 完成初始化。", "continue": true}
JSON
    exit 0
fi

PHASE=$(jq -r '.phase // "0"' "$STATE_FILE")
STEP=$(jq -r '.step // ""' "$STATE_FILE")
FEATURE=$(jq -r '.feature // ""' "$STATE_FILE")

# Read the file being edited from stdin
FILE_PATH=$(jq -r '.tool_input.file_path // ""')

# Only check for code files (exclude .devflow/, .claude/, docs/)
if [ "$PHASE" -lt 1 ] 2>/dev/null; then
    # Phase 0 or 0.5 — check if editing a code file
    if echo "$FILE_PATH" | grep -qE '\.(js|ts|py|go|rs|rb|php|c|cpp|h|hpp|java|kt|swift)$'; then
        cat <<JSON
{"systemMessage": "⚠️ devflow 流程提醒: 当前 Phase $PHASE（$STEP），尚未完成需求梳理。正在尝试修改代码文件。建议先完成 Phase 0 流程。如需继续请确认。", "continue": true}
JSON
        exit 0
    fi
fi

# Check for skipping steps — if in Phase 2 but jumping to implementation without plan
if [ "$PHASE" -eq 2 ] && [ "$STEP" = "brainstorming" ]; then
    if echo "$FILE_PATH" | grep -qE '\.(js|ts|py|go)$'; then
        cat <<JSON
{"systemMessage": "⚠️ devflow 流程提醒: 当前在 brainstorming 阶段，直接写代码会跳过 grill → plans → scenario 等步骤。请完成当前阶段后再开始实现。", "continue": true}
JSON
        exit 0
    fi
fi

# All good — no message needed
echo '{"continue": true}'
