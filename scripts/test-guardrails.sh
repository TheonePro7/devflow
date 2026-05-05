#!/usr/bin/env bash
# test-guardrails.sh
# Validate git guardrails hook behavior for bash implementation.
# Exit code: 0 = all tests pass, 1 = some tests failed.
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

passed=0
failed=0

test_command() {
  local desc="$1" command="$2" expected="$3"

  # Simulate stdin JSON
  local json='{"tool_name":"Bash","tool_input":{"command":"'"$command"'"}}'

  # Test bash guardrails
  local result
  result=$(echo "$json" | bash .claude/hooks/guardrails-git.sh 2>/dev/null || true)
  local denied=1
  echo "$result" | grep -q "permissionDecision.*deny" && denied=0

  if [ "$expected" = "block" ] && [ "$denied" -eq 0 ]; then
    passed=$((passed + 1))
    echo "[PASS] $desc"
  elif [ "$expected" = "allow" ] && [ "$denied" -ne 0 ]; then
    passed=$((passed + 1))
    echo "[PASS] $desc"
  else
    failed=$((failed + 1))
    echo "[FAIL] $desc"
    echo "       expected=$expected got=$([ "$denied" -eq 0 ] && echo 'block' || echo 'allow')"
    echo "       output: $result"
  fi
}

echo "=== Git Guardrails Validation (bash) ==="
echo ""

# --- Dangerous commands that MUST be blocked ---
echo "--- Block tests (dangerous patterns) ---"
test_command "git push --force" "git push --force" "block"
test_command "git push -f" "git push -f" "block"
test_command "git reset --hard" "git reset --hard" "block"
test_command "git clean -fd" "git clean -fd" "block"
test_command "git clean -df" "git clean -df" "block"
test_command "git branch -D" "git branch -D" "block"
test_command "git checkout ." "git checkout ." "block"
test_command "git checkout -- file" "git checkout -- file" "block"
test_command "git restore ." "git restore ." "block"
test_command "git restore --staged ." "git restore --staged ." "block"
test_command "git rebase --skip" "git rebase --skip" "block"
test_command "git merge --abort" "git merge --abort" "block"

# --- Safe commands that MUST be allowed ---
echo ""
echo "--- Allow tests (safe patterns) ---"
test_command "git status" "git status" "allow"
test_command "git diff" "git diff" "allow"
test_command "git add file.txt" "git add file.txt" "allow"
test_command "git commit -m msg" "git commit -m msg" "allow"
test_command "git push origin main" "git push origin main" "allow"
test_command "git checkout -b feature" "git checkout -b feature" "allow"
test_command "git branch feature" "git branch feature" "allow"
test_command "git log" "git log" "allow"
test_command "git pull" "git pull" "allow"
test_command "git restore file.txt" "git restore file.txt" "allow"

# --- Edge cases ---
echo ""
echo "--- Edge cases ---"
test_command "git push --force-with-lease" "git push --force-with-lease" "allow"
test_command "git reset --soft HEAD^" "git reset --soft HEAD^" "allow"

echo ""
echo "=== Results: $passed passed, $failed failed ==="
exit $([ "$failed" -gt 0 ] && echo 1 || echo 0)
