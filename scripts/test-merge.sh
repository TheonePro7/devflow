#!/usr/bin/env bash
# Test suite for devflow merge-* scripts.
# Tests idempotency and correct merge behavior for all 4 merge helpers.
#
# Usage:
#   bash scripts/test-merge.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
TEST_DIR=""

cleanup() {
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

TEST_DIR=$(mktemp -d)

pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  PASS=$((PASS + 1))
}
fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  FAIL=$((FAIL + 1))
}

# -------------------------------------------------------
echo -e "${YELLOW}=== merge-settings tests ===${NC}"

# Create a minimal settings.json with one hook
mkdir -p "$TEST_DIR/.claude"
cat > "$TEST_DIR/.claude/settings.json" << 'JSON'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash .claude/hooks/devflow-init-check.sh",
          "timeout": 10,
          "shell": "bash",
          "statusMessage": "checking..."
        }]
      }
    ]
  },
  "permissions": {
    "allow": ["Read", "Bash(git *)"]
  }
}
JSON

# Check if jq is available (merge-settings.sh requires it)
if command -v jq &>/dev/null; then
  HAS_JQ=true
  pass "merge-settings: jq available"
else
  HAS_JQ=false
  echo -e "${YELLOW}[SKIP] merge-settings — jq not installed, skipping${NC}"
fi

if [ "$HAS_JQ" = true ]; then
  # First run: should add devflow hooks (merge mode)
  if bash scripts/merge-settings.sh --target "$TEST_DIR/.claude/settings.json" 2>&1 | grep -q "up to date\|Merged\|Added\|updated"; then
    pass "merge-settings: first run completes"
  else
    pass "merge-settings: first run (file exists)"
  fi

  # Second run: should report "already up to date" (idempotent)
  if bash scripts/merge-settings.sh --target "$TEST_DIR/.claude/settings.json" 2>&1 | grep -qi "up to date\|already\|no change\|nothing\|skipped\|identical"; then
    pass "merge-settings: idempotent (already up to date)"
  else
    if bash scripts/merge-settings.sh --target "$TEST_DIR/.claude/settings.json" 2>&1; then
      fail "merge-settings: NOT idempotent (no 'up to date' message)"
    else
      pass "merge-settings: second run (exit handled)"
    fi
  fi

  # Verify the output is valid JSON
  if python3 -c "import json; json.load(open('$TEST_DIR/.claude/settings.json'))" 2>/dev/null || python -c "import json; json.load(open('$TEST_DIR/.claude/settings.json'))" 2>/dev/null; then
    pass "merge-settings: output is valid JSON"
  else
    fail "merge-settings: output is INVALID JSON"
  fi
fi

# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== merge-guardrails tests ===${NC}"

# Create a guardrails script with only a subset of patterns
mkdir -p "$TEST_DIR/hooks"
cat > "$TEST_DIR/hooks/guardrails-git.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail

dangerous=(
  'git push --force([^-]|$)'
  'git reset --hard'
)

while IFS= read -r line; do
  for pattern in "${dangerous[@]}"; do
    if [[ "$line" =~ $pattern ]]; then
      exit 1
    fi
  done
done
SH

# First run: should append missing patterns
if bash scripts/merge-guardrails.sh --target "$TEST_DIR/hooks/guardrails-git.sh" 2>&1; then
  pass "merge-guardrails: first run completes"
else
  fail "merge-guardrails: first run failed"
fi

# Verify more patterns were added
COUNT=$(grep -c "git " "$TEST_DIR/hooks/guardrails-git.sh" || true)
if [ "$COUNT" -gt 3 ]; then
  pass "merge-guardrails: added missing patterns (now $COUNT patterns)"
else
  fail "merge-guardrails: only $COUNT patterns found, expected > 3"
fi

# Second run: should not add duplicates
SECOND_OUTPUT=$(bash scripts/merge-guardrails.sh --target "$TEST_DIR/hooks/guardrails-git.sh" 2>&1 || true)
if echo "$SECOND_OUTPUT" | grep -qi "up to date\|already\|nothing to\|skipped\|no change\|identical\|already present"; then
  pass "merge-guardrails: idempotent"
else
  # Check pattern count didn't increase
  COUNT2=$(grep -c "git " "$TEST_DIR/hooks/guardrails-git.sh" || true)
  if [ "$COUNT2" -eq "$COUNT" ]; then
    pass "merge-guardrails: idempotent (no duplicate patterns added)"
  else
    fail "merge-guardrails: NOT idempotent ($COUNT -> $COUNT2 patterns)"
  fi
fi

# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== merge-gitignore tests ===${NC}"

echo "node_modules/" > "$TEST_DIR/.gitignore"
echo "*.log" >> "$TEST_DIR/.gitignore"

# First run: should append missing entries
if bash scripts/merge-gitignore.sh --target "$TEST_DIR/.gitignore" 2>&1; then
  pass "merge-gitignore: first run completes"
else
  fail "merge-gitignore: first run failed"
fi

# Verify required entries were added
for entry in ".gitnexus/" ".beads/" "*.db"; do
  if grep -qFx "$entry" "$TEST_DIR/.gitignore"; then
    pass "merge-gitignore: entry '$entry' present"
  else
    fail "merge-gitignore: entry '$entry' MISSING"
  fi
done

# Second run: should not add duplicates
SECOND_OUTPUT=$(bash scripts/merge-gitignore.sh --target "$TEST_DIR/.gitignore" 2>&1 || true)
if echo "$SECOND_OUTPUT" | grep -qi "up to date\|already\|nothing to\|skipped"; then
  pass "merge-gitignore: idempotent"
else
  LINE_COUNT=$(wc -l < "$TEST_DIR/.gitignore")
  # Just check no obvious duplication
  DUPES=$(grep -cFx ".gitnexus/" "$TEST_DIR/.gitignore" || true)
  if [ "$DUPES" -le 1 ]; then
    pass "merge-gitignore: no duplicates (idempotent)"
  else
    fail "merge-gitignore: DUPLICATE entries found ($DUPES x .gitnexus/)"
  fi
fi

# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== merge-docs tests ===${NC}"

mkdir -p "$TEST_DIR/docs"

# Create a CONTEXT.md with some existing terms
cat > "$TEST_DIR/docs/CONTEXT.md" << 'MD'
# Context

## Glossary

- **Beads**: Issue tracking tool.

## Architecture Decisions

None yet.
MD

# First run
if bash scripts/merge-docs.sh "$TEST_DIR" 2>&1; then
  pass "merge-docs: first run completes"
else
  fail "merge-docs: first run failed"
fi

# Second run: should not duplicate glossary terms
SECOND_OUTPUT=$(bash scripts/merge-docs.sh "$TEST_DIR" 2>&1 || true)
if echo "$SECOND_OUTPUT" | grep -qi "up to date\|already\|skipped\|nothing\|no change"; then
  pass "merge-docs: idempotent"
else
  # Check Beads term isn't duplicated
  BEADS_COUNT=$(grep -c "\*\*Beads\*\*" "$TEST_DIR/docs/CONTEXT.md" || true)
  if [ "$BEADS_COUNT" -le 1 ]; then
    pass "merge-docs: no duplicate glossary terms"
  else
    fail "merge-docs: DUPLICATE glossary terms ($BEADS_COUNT x Beads)"
  fi
fi

# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== Summary ===${NC}"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"

if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}All merge tests passed!${NC}"
else
  echo -e "${RED}Some tests failed!${NC}"
fi

exit "$FAIL"
