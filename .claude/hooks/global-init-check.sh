#!/usr/bin/env bash
# global-devflow-check.sh
# Global SessionStart hook — runs in every project.
# If .devflow/state is missing, tells the agent devflow is available but uninitialized.
set -euo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

if [ ! -f "$PROJECT_ROOT/.devflow/state" ]; then
  # Check if devflow skill is installed
  if [ -f "$HOME/.claude/skills/devflow/setup.sh" ]; then
    printf '{"systemMessage":"⚙️ devflow 检测到新项目。输入「用 devflow 开发」自动初始化并启动 5 阶段流程。（或手动运行: bash ~/.claude/skills/devflow/setup.sh）","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"devflow skill 已安装但本项目尚未初始化(.devflow/state 不存在)。如需使用 devflow 流程，先运行 setup.sh 初始化。"}}'
  fi
fi

exit 0
