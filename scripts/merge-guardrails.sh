#!/usr/bin/env bash
# merge-guardrails.sh
# Detect existing bash guardrails patterns and merge (diff+append) devflow's patterns.
#
# Usage:
#   bash scripts/merge-guardrails.sh          # Merge & write
#   bash scripts/merge-guardrails.sh --dry-run # Preview only
#   bash scripts/merge-guardrails.sh --target <path>
#
# Exit codes: 0 = up to date or merged, 1 = error

set -euo pipefail

TARGET=".claude/hooks/guardrails-git.sh"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Devflow's canonical dangerous patterns for bash
DEVFLOW_PATTERNS=(
  'git push --force([^-]|$)'
  'git push -f([^-]|$)'
  'git reset --hard([^-]|$)'
  'git clean -fd([^-]|$)'
  'git clean -df([^-]|$)'
  'git branch -D([^-]|$)'
  'git checkout \.'
  'git checkout --'
  'git restore \.'
  'git restore --staged \.'
  'git rebase --skip([^-]|$)'
  'git merge --abort([^-]|$)'
)

# Extract patterns from existing bash guardrails file.
# Uses sed to grab all single-quoted strings inside the dangerous=(...) block.
# Outputs one pattern per line to stdout.
extract_patterns() {
  local file="$1"

  if [ ! -f "$file" ]; then
    return
  fi

  # Find the dangerous=( block and extract all single-quoted strings
  # sed range: /^dangerous=(/,/^)/  — between array start and end
  # then extract content of single quotes
  sed -n '/^[[:space:]]*dangerous=(/,/^[[:space:]]*)/ {
    /^[[:space:]]*dangerous=(/d       # delete the opening line
    /^[[:space:]]*)/d                 # delete the closing line
    /^[[:space:]]*#/d                 # delete comments
    s/^[[:space:]]*//                 # strip leading whitespace
    s/^./&/                           # noop — ensure we print non-empty
    /^$/d                             # delete empty lines
    p                                 # print what remains
  }' "$file" | sed "s/^'//; s/'$//"   # strip surrounding single quotes
}

# Check if a value exists in an array (using literal comparison)
array_contains() {
  local needle="$1"
  shift
  for elem in "$@"; do
    if [ "$needle" = "$elem" ]; then
      return 0
    fi
  done
  return 1
}

# Main merge logic
merge_guardrails() {
  local path="$1"
  local dry_run="$2"

  if [ ! -f "$path" ]; then
    echo "[SKIP] No existing guardrails at $path — nothing to merge."
    return
  fi

  # Read existing patterns into array (one per line from extract_patterns)
  local -a existing=()
  while IFS= read -r pat; do
    existing+=("$pat")
  done < <(extract_patterns "$path")

  if [ ${#existing[@]} -eq 0 ]; then
    echo "[WARN] Could not parse 'dangerous=(' array from $path"
    echo "       Recommended: reinstall guardrails via setup script."
    return
  fi

  # Diff: find patterns in devflow list that are NOT in existing
  local -a missing=()
  local df
  for df in "${DEVFLOW_PATTERNS[@]}"; do
    if ! array_contains "$df" "${existing[@]}"; then
      missing+=("$df")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    echo "[OK] Guardrails already up to date (${#existing[@]} patterns)."
    return
  fi

  if [ "$dry_run" = true ]; then
    echo "=== DRY RUN — Would append to $path ==="
    echo "Existing patterns: ${#existing[@]}"
    echo "Missing patterns: ${#missing[@]}"
    for p in "${missing[@]}"; do
      echo "  + $p"
    done
    return
  fi

  # Read file into array
  local -a lines=()
  local last_pattern_line=-1
  local close_paren_line=-1
  local line_num=0

  while IFS= read -r line; do
    lines+=("$line")
    local trimmed
    trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
    # A pattern line contains a single-quoted string
    if printf '%s' "$trimmed" | grep -q "'[^']*'" && printf '%s' "$trimmed" | grep -v -q '^dangerous='; then
      last_pattern_line=$line_num
    fi
    if printf '%s' "$trimmed" | grep -q '^)$'; then
      close_paren_line=$line_num
    fi
    line_num=$((line_num + 1))
  done < "$path"

  if [ "$last_pattern_line" -ge 0 ] && [ "$close_paren_line" -gt "$last_pattern_line" ]; then
    local indent
    indent=$(printf '%s' "${lines[$last_pattern_line]}" | sed 's/[^[:space:]].*//')

    local -a output=()
    local i
    for ((i=0; i<=last_pattern_line; i++)); do
      output+=("${lines[$i]}")
    done
    for p in "${missing[@]}"; do
      output+=("${indent}'${p}'")
    done
    for ((i=close_paren_line; i<${#lines[@]}; i++)); do
      output+=("${lines[$i]}")
    done

    printf '%s\n' "${output[@]}" > "$path"
    echo "[OK] Appended ${#missing[@]} missing pattern(s) to $path"
    for p in "${missing[@]}"; do
      echo "  + $p"
    done
  else
    echo "[ERROR] Could not find pattern array boundaries in $path"
    return 1
  fi
}

# --- Main ---
merge_guardrails "$TARGET" "$DRY_RUN"
