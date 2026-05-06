#!/usr/bin/env bash
# devflow-state-check.sh
# UserPromptSubmit hook — injects current devflow state as context.
# Reads .devflow/state and outputs a reminder message.
set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
STATE_FILE="$PROJECT_ROOT/.devflow/state"

if [ -f "$STATE_FILE" ]; then
    PHASE=$(jq -r '.phase // ""' "$STATE_FILE")
    STEP=$(jq -r '.step // ""' "$STATE_FILE")
    FEATURE=$(jq -r '.feature // ""' "$STATE_FILE")
    GATE_PROBE=$(jq -r '.gate_probe // ""' "$STATE_FILE")
    GATE_SCENARIO=$(jq -r '.gate_scenario // ""' "$STATE_FILE")
    GATE_FIX=$(jq -r '.gate_fix // ""' "$STATE_FILE")
    GATE_SECURITY=$(jq -r '.gate_security // ""' "$STATE_FILE")

    if [ -z "$FEATURE" ] || [ "$FEATURE" = "null" ]; then
        cat <<'JSON'
{"systemMessage": "⚙️ devflow: 当前没有进行中的功能。如果用户提出新想法，请先读取 .devflow/state 并按 phase 阶段执行，不要直接写代码。"}
JSON
    elif [ "$PHASE" = "4" ] && [ -n "$GATE_PROBE" ]; then
        cat <<JSON
{"systemMessage": "⚙️ devflow 状态追踪: [Phase $PHASE] [Step: $STEP] 功能: $FEATURE | 门禁: probe=$GATE_PROBE scenario=$GATE_SCENARIO fix=$GATE_FIX security=$GATE_SECURITY。请按 devflow 流程执行当前步骤，门禁未完成会被 Hook 拦截。"}
JSON
    else
        cat <<JSON
{"systemMessage": "⚙️ devflow 状态追踪: [Phase $PHASE] [Step: $STEP] 功能: $FEATURE。请按 devflow 流程执行当前步骤，不要跳步骤。"}
JSON
    fi
else
    cat <<'JSON'
{"systemMessage": "⚙️ devflow: .devflow/state 不存在。需要先运行 setup 完成初始化。"}
JSON
fi
