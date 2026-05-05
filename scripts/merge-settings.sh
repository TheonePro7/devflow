#!/usr/bin/env bash
# merge-settings.sh
# Merge devflow settings into existing .claude/settings.json with dedup.
# Requires: jq
#
# Usage:
#   bash scripts/merge-settings.sh                    # Merge & write
#   bash scripts/merge-settings.sh --dry-run           # Preview only
#   bash scripts/merge-settings.sh --target <path>     # Custom target
#
# Exit codes: 0 = success, 1 = merge error, 2 = missing deps

set -euo pipefail

TARGET=".claude/settings.json"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Dependency check ---
if ! command -v jq &>/dev/null; then
  echo "[ERROR] jq is required but not installed." >&2
  echo "        Install: winget install jqlang.jq  or  apt install jq  or  brew install jq" >&2
  exit 2
fi

# --- Devflow defaults as JSON string ---
# These are the baseline settings devflow needs.
DEVFLOW_DEFAULTS='{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bd prime" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "powershell -NoProfile -File .claude/hooks/guardrails-git.ps1",
            "timeout": 5,
            "statusMessage": "devflow: checking git safety..."
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "command": "bash .claude/hooks/guardrails-git.sh",
            "timeout": 5,
            "statusMessage": "devflow: checking git safety..."
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "powershell -File .claude/hooks/devflow-init-check.ps1",
            "timeout": 10,
            "statusMessage": "devflow: checking project state..."
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "command": "bash .claude/hooks/devflow-init-check.sh",
            "timeout": 10,
            "statusMessage": "devflow: checking project state..."
          }
        ]
      },
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bd prime" }
        ]
      }
    ]
  },
  "permissions": {
    "additionalDirectories": [
      "'"$HOME"'/.claude/skills/superpowers-brainstorming",
      "'"$HOME"'/.claude/skills/superpowers-writing-plans",
      "'"$HOME"'/.claude/skills/superpowers-using-git-worktrees",
      "'"$HOME"'/.claude/skills/superpowers-subagent-driven-development",
      "'"$HOME"'/.claude/skills/superpowers-requesting-code-review",
      "'"$HOME"'/.claude/skills/superpowers-finishing-a-development-branch",
      "'"$HOME"'/.claude/skills/superpowers-test-driven-development"
    ]
  }
}'

# --- jq filter: merge hooks with dedup ---
# Strategy:
#   1. For each hook event in devflow defaults, check if user already has
#      a hook entry with matching (matcher, hooks[0].command, hooks[0].type, hooks[0].shell)
#   2. Append only those that are missing
#   3. Preserve existing hooks entirely

MERGE_FILTER='
# Normalize path for cross-platform dedup: lowercase, forward slashes, normalize drive letter
def normalize_path:
  ascii_downcase
  | gsub("\\\\"; "/")
  | (capture("^(?<d>[a-z]):/(?<r>.*)") // null) as $c
  | if $c then "/\($c.d)/\($c.r)" else . end
;

# Helper: generate a dedup key for a hook entry
def hook_key(entry):
  (entry.matcher // "") as $m
  | (entry.hooks[0].command // "") as $c
  | (entry.hooks[0].type // "command") as $t
  | (entry.hooks[0].shell // "") as $s
  | "\($m)|\($c)|\($t)|\($s)"
;

# Remove null-valued fields recursively
def clean_nulls:
  if type == "object" then
    with_entries(select(.value != null) | .value |= clean_nulls)
  elif type == "array" then
    map(clean_nulls)
  else .
  end
;

# Start with devflow defaults as base
. as $existing
| $devflow as $df
|
# Merge hooks: for each event in devflow, append entries not in existing
($df.hooks | to_entries) as $dfHookEvents
| reduce $dfHookEvents[] as $evt (.;
  $evt.key as $eventName
  | $evt.value as $dfEntries
  | $existing.hooks[$eventName] as $exEntries
  | if $exEntries then
      (reduce $exEntries[] as $e ({}; .[hook_key($e)] = true)) as $exKeys
      | .hooks[$eventName] = ($exEntries + [$dfEntries[] | select(. as $e | $exKeys[hook_key($e)] | not)])
    else
      .hooks[$eventName] = $dfEntries
    end
)
|
# Merge additionalDirectories (dedup by normalized path)
.hooks as $mergedHooks
| $existing.permissions.additionalDirectories // [] as $exDirs
| $devflow.permissions.additionalDirectories as $dfDirs
| (reduce $exDirs[] as $d ({}; .[$d | normalize_path] = $d)) as $exDirMap
| .permissions.additionalDirectories = (
    ($exDirs + [$dfDirs[] | select(. | normalize_path | IN($exDirMap | keys[]) | not)])
  )
|
# Preserve existing permission fields (only if present and not null)
if $existing.permissions then
  (if $existing.permissions.allow then .permissions.allow = $existing.permissions.allow else . end)
  | (if $existing.permissions.deny then .permissions.deny = $existing.permissions.deny else . end)
  | (if $existing.permissions.ask then .permissions.ask = $existing.permissions.ask else . end)
  | (if $existing.permissions.defaultMode then .permissions.defaultMode = $existing.permissions.defaultMode else . end)
else . end
|
# Clean nulls from permissions and top-level
.permissions |= clean_nulls
|
# Preserve existing top-level settings
if $existing."$schema" then ."$schema" = $existing."$schema" else . end
| if $existing.env then .env = $existing.env else . end
| if $existing.language then .language = $existing.language else . end
| if $existing.model then .model = $existing.model else . end
| if $existing.attribution then .attribution = $existing.attribution else . end
| if $existing.respectGitignore then .respectGitignore = $existing.respectGitignore else . end
| if $existing.cleanupPeriodDays then .cleanupPeriodDays = $existing.cleanupPeriodDays else . end
| if $existing.enabledPlugins then .enabledPlugins = $existing.enabledPlugins else . end
'

# --- Main ---
HAD_PARSE_ERROR=false

if [ -f "$TARGET" ]; then
  # Validate existing JSON
  if ! jq empty "$TARGET" 2>/dev/null; then
    HAD_PARSE_ERROR=true
    echo "[WARN] $TARGET has syntax errors — backing up and starting fresh." >&2
    cp "$TARGET" "$TARGET.bak"
    echo "[BAK] Saved backup to $TARGET.bak"
  fi
fi

if [ "$DRY_RUN" = true ]; then
  echo "=== DRY RUN — Would merge into $TARGET ==="
  if [ -f "$TARGET" ] && [ "$HAD_PARSE_ERROR" = false ]; then
    jq --argjson devflow "$DEVFLOW_DEFAULTS" "$MERGE_FILTER" "$TARGET"
  else
    echo "$DEVFLOW_DEFAULTS" | jq .
  fi
  exit 0
fi

# Ensure directory exists
mkdir -p "$(dirname "$TARGET")"

if [ -f "$TARGET" ] && [ "$HAD_PARSE_ERROR" = false ]; then
  # Merge with existing
  jq --argjson devflow "$DEVFLOW_DEFAULTS" "$MERGE_FILTER" "$TARGET" > "${TARGET}.tmp"
  mv "${TARGET}.tmp" "$TARGET"
else
  # No existing file or parse error — write devflow defaults
  echo "$DEVFLOW_DEFAULTS" > "$TARGET"
fi

echo "[OK] Merged settings written to $TARGET"

if [ "$HAD_PARSE_ERROR" = true ]; then
  echo "[INFO] Previous settings were backed up to $TARGET.bak"
fi
