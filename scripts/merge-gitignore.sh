#!/usr/bin/env bash
# merge-gitignore.sh
# Merge devflow-required entries into .gitignore.
# For each required entry, grep-check exact line; append only if missing.
# Idempotent.
#
# Usage:
#   bash scripts/merge-gitignore.sh          # Merge & write
#   bash scripts/merge-gitignore.sh --dry-run # Preview only
#   bash scripts/merge-gitignore.sh --target <path>

set -euo pipefail

TARGET=".gitignore"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Entries devflow needs in .gitignore
REQUIRED=(
  ".gitnexus/"
  ".beads/"
  ".dolt/"
  "*.db"
  ".beads-credential-key"
  ".claude/settings.local.json"
)

MISSING=()

for entry in "${REQUIRED[@]}"; do
  if [ -f "$TARGET" ]; then
    if grep -qFx "$entry" "$TARGET" 2>/dev/null; then
      continue  # already present
    fi
  fi
  MISSING+=("$entry")
done

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "[OK] .gitignore already up to date."
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  echo "=== DRY RUN — Would append to $TARGET ==="
  for e in "${MISSING[@]}"; do echo "  + $e"; done
  exit 0
fi

for entry in "${MISSING[@]}"; do
  echo "$entry" >> "$TARGET"
done

echo "[OK] Appended ${#MISSING[@]} missing entry/entries to $TARGET"
for e in "${MISSING[@]}"; do echo "  + $e"; done
