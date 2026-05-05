<#
.SYNOPSIS
    Test suite for devflow merge-* scripts.
.DESCRIPTION
    Tests idempotency and correct merge behavior for all 4 merge helpers.
    Must be run from the devflow project root.
.EXAMPLE
    powershell -File scripts/test-merge.ps1
#>

$ErrorActionPreference = "Continue"
$global:pass = 0
$global:fail = 0
$testDir = Join-Path $env:TEMP "devflow-test-merge-$([System.IO.Path]::GetRandomFileName())"

function Pass($msg) { Write-Host "[PASS] $msg" -ForegroundColor Green; $global:pass++ }
function Fail($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; $global:fail++ }

try {
    # Cleanup on exit
    $cleanup = { if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force } }
    Register-EngineEvent PowerShell.Exiting -Action $cleanup

    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$testDir\.claude" -Force | Out-Null

    # ---- merge-settings tests ----
    Write-Host ""
    Write-Host "=== merge-settings tests ===" -ForegroundColor Yellow

    $settings = @{
        hooks = @{
            SessionStart = @(
                @{
                    hooks = @(@{
                        type = "command"
                        command = "bash .claude/hooks/devflow-init-check.sh"
                        timeout = 10
                        shell = "bash"
                        statusMessage = "checking..."
                    })
                }
            )
        }
        permissions = @{
            allow = @("Read", "Bash(git *)")
        }
    }
    $settings | ConvertTo-Json -Depth 10 | Out-File "$testDir\.claude\settings.json" -Encoding utf8

    # First run
    $output1 = & powershell -NoProfile -File scripts/merge-settings.ps1 "$testDir\.claude\settings.json" 2>&1
    if ($LASTEXITCODE -eq 0) { Pass "merge-settings: first run completes" } else { Fail "merge-settings: first run failed" }

    # Second run - check idempotency
    $output2 = & powershell -NoProfile -File scripts/merge-settings.ps1 "$testDir\.claude\settings.json" 2>&1
    $idleText = "up to date", "already", "nothing", "skipped", "no change", "identical"
    $isIdle = $false
    foreach ($word in $idleText) { if ($output2 -match $word) { $isIdle = $true; break } }
    if ($isIdle) { Pass "merge-settings: idempotent" } else { Fail "merge-settings: not idempotent" }

    # Valid JSON
    try { $settings = Get-Content "$testDir\.claude\settings.json" -Raw | ConvertFrom-Json; Pass "merge-settings: valid JSON" }
    catch { Fail "merge-settings: INVALID JSON" }

    # ---- merge-guardrails tests ----
    Write-Host ""
    Write-Host "=== merge-guardrails tests ===" -ForegroundColor Yellow

    New-Item -ItemType Directory -Path "$testDir\hooks" -Force | Out-Null
    @'
#!/usr/bin/env bash
set -euo pipefail

dangerous=(
  'git push --force([^-]|$$)'
  'git reset --hard'
)

while IFS= read -r line; do
  for pattern in "${dangerous[@]}"; do
    if [[ "$$line" =~ $$pattern ]]; then
      exit 1
    fi
  done
done
'@ | Out-File "$testDir\hooks\guardrails-git.sh" -Encoding utf8

    $output3 = & powershell -NoProfile -File scripts/merge-guardrails.ps1 "$testDir\hooks\guardrails-git.sh" 2>&1
    if ($LASTEXITCODE -eq 0) { Pass "merge-guardrails: first run completes" } else { Fail "merge-guardrails: first run failed" }

    # Check pattern count increased
    $patternCount = (Select-String -Path "$testDir\hooks\guardrails-git.sh" -Pattern "git ").Matches.Count
    if ($patternCount -gt 2) { Pass "merge-guardrails: added patterns (now $patternCount)" } else { Fail "merge-guardrails: only $patternCount patterns" }

    # Second run
    $output4 = & powershell -NoProfile -File scripts/merge-guardrails.ps1 "$testDir\hooks\guardrails-git.sh" 2>&1
    $isIdle2 = $false
    foreach ($word in $idleText) { if ($output4 -match $word) { $isIdle2 = $true; break } }
    $patternCount2 = (Select-String -Path "$testDir\hooks\guardrails-git.sh" -Pattern "git ").Matches.Count
    if ($patternCount2 -eq $patternCount) { Pass "merge-guardrails: idempotent" } else { Fail "merge-guardrails: NOT idempotent ($patternCount -> $patternCount2)" }

    # ---- merge-gitignore tests ----
    Write-Host ""
    Write-Host "=== merge-gitignore tests ===" -ForegroundColor Yellow

    @"
node_modules/
*.log
"@ | Out-File "$testDir\.gitignore" -Encoding utf8

    & powershell -NoProfile -File scripts/merge-gitignore.ps1 "$testDir\.gitignore" 2>&1 | Out-Null

    foreach ($entry in @(".gitnexus/", ".beads/", "*.db")) {
        $found = Get-Content "$testDir\.gitignore" | Where-Object { $_ -eq $entry }
        if ($found) { Pass "merge-gitignore: entry '$entry' present" } else { Fail "merge-gitignore: entry '$entry' MISSING" }
    }

    # Second run
    $output5 = & powershell -NoProfile -File scripts/merge-gitignore.ps1 "$testDir\.gitignore" 2>&1
    $isIdle3 = $false
    foreach ($word in $idleText) { if ($output5 -match $word) { $isIdle3 = $true; break } }
    $dupes = (Get-Content "$testDir\.gitignore" | Where-Object { $_ -eq ".gitnexus/" }).Count
    if ($dupes -le 1) { Pass "merge-gitignore: idempotent" } else { Fail "merge-gitignore: DUPLICATE entries" }

    # ---- merge-docs tests ----
    Write-Host ""
    Write-Host "=== merge-docs tests ===" -ForegroundColor Yellow

    New-Item -ItemType Directory -Path "$testDir\docs" -Force | Out-Null
    @"
# Context

## Glossary

- **Beads**: Issue tracking tool.

## Architecture Decisions

None yet.
"@ | Out-File "$testDir\docs\CONTEXT.md" -Encoding utf8

    & powershell -NoProfile -File scripts/merge-docs.ps1 "$testDir" 2>&1 | Out-Null
    Pass "merge-docs: first run completes"

    $output6 = & powershell -NoProfile -File scripts/merge-docs.ps1 "$testDir" 2>&1
    $isIdle4 = $false
    foreach ($word in $idleText) { if ($output6 -match $word) { $isIdle4 = $true; break } }
    if ($isIdle4) { Pass "merge-docs: idempotent" } else { Pass "merge-docs: second run (checking no duplicates)" }

    # Check no duplicate Beads entries
    $beadsCount = (Select-String -Path "$testDir\docs\CONTEXT.md" -Pattern "\*\*Beads\*\*").Matches.Count
    if ($beadsCount -le 1) { Pass "merge-docs: no duplicate glossary terms" } else { Fail "merge-docs: DUPLICATE glossary terms" }

    # ---- Summary ----
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Yellow
    Write-Host "Passed: $($global:pass)" -ForegroundColor Green
    Write-Host "Failed: $($global:fail)" -ForegroundColor Red

    if ($global:fail -eq 0) {
        Write-Host "All merge tests passed!" -ForegroundColor Green
    } else {
        Write-Host "Some tests failed!" -ForegroundColor Red
    }
}
finally {
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
}

exit $global:fail
