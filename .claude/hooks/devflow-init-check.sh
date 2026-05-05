#!/usr/bin/env bash
# devflow-init-check.sh
# Claude Code SessionStart hook (bash/Unix/macOS)
# Checks if devflow Phase 1 has been initialized in this project.
# Output: structured JSON for Claude context injection.
# Install via: .claude/settings.json -> hooks.SessionStart
set -euo pipefail

# Check prerequisites (tool availability)
bd_installed=0
gitnexus_installed=0
command -v bd &>/dev/null && bd_installed=1
command -v gitnexus &>/dev/null && gitnexus_installed=1

# Check project initialization
beads_init=0
gitnexus_init=0
[ -d .beads ] && beads_init=1
[ -d .gitnexus ] && gitnexus_init=1

# Determine state
all_ok=1
[ "$bd_installed" -eq 1 ] && [ "$gitnexus_installed" -eq 1 ] && [ "$beads_init" -eq 1 ] && [ "$gitnexus_init" -eq 1 ] || all_ok=0

if [ "$all_ok" -eq 0 ]; then
  issues=""
  [ "$bd_installed" -eq 0 ] && issues="${issues}beads (bd) not installed; "
  [ "$gitnexus_installed" -eq 0 ] && issues="${issues}gitnexus not installed; "
  [ "$beads_init" -eq 0 ] && issues="${issues}beads not initialized (run 'bd init'); "
  [ "$gitnexus_init" -eq 0 ] && issues="${issues}gitnexus index not built (run 'gitnexus analyze .'); "
  issues="${issues%; }"

  summary="devflow Phase 1 pending — ${issues}"
  system_msg="devflow: Phase 1 not initialized. Setup will auto-run now — agent will execute setup.ps1 or setup.sh."

  if command -v jq &>/dev/null; then
    jq -n \
      --arg msg "$system_msg" \
      --arg ctx "$summary" \
      '{$msg, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
  else
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$system_msg" "$summary"
  fi
else
  # Phase 1 OK — always inject context so SKILL.md auto-triggers
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"devflow Phase 1 ready — beads + gitnexus + autoresearch initialized. devflow 3-phase orchestrator available."}}'
fi

exit 0
