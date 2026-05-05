<#
.SYNOPSIS
    Validate git guardrails hook behavior for both PowerShell and bash implementations.
.DESCRIPTION
    Tests each dangerous pattern and safe commands to ensure correct block/allow decisions.
    Exit code: 0 = all tests pass, 1 = some tests failed.
#>

$ErrorActionPreference = "Stop"
$passed = 0
$failed = 0

# Check which shells are available
$bashAvailable = $false
try {
    $null = & bash --version 2>&1
    $bashAvailable = $LASTEXITCODE -eq 0
} catch {
    $bashAvailable = $false
}
if (-not $bashAvailable) {
    Write-Host "[INFO] bash not available — skipping bash guardrails tests" -ForegroundColor Yellow
}

function Test-Command {
    param([string]$Desc, [string]$Command, [string]$Expected)
    # Simulate the stdin JSON the hook receives
    $json = "{`"tool_name`":`"Bash`",`"tool_input`":{`"command`":`"$Command`"}}"

    # Test PowerShell guardrails
    $psResult = $json | powershell -NoProfile -File ".claude/hooks/guardrails-git.ps1" 2>$null
    $psDenied = $psResult -match "permissionDecision.*deny"
    $psOk = ($Expected -eq "block" -and $psDenied) -or ($Expected -eq "allow" -and -not $psDenied)

    # Test bash guardrails (if available)
    $baOk = $true
    if ($global:bashAvailable) {
        $baResult = $json | bash ".claude/hooks/guardrails-git.sh" 2>$null
        $baDenied = $baResult -match "permissionDecision.*deny"
        $baOk = ($Expected -eq "block" -and $baDenied) -or ($Expected -eq "allow" -and -not $baDenied)
    }

    if ($psOk -and $baOk) {
        $global:passed++
        Write-Host "[PASS] $Desc" -ForegroundColor Green
    } else {
        $global:failed++
        Write-Host "[FAIL] $Desc" -ForegroundColor Red
        if (-not $psOk) {
            Write-Host "       PS expected=$Expected got=$(if($psDenied){'block'}else{'allow'})" -ForegroundColor Gray
            Write-Host "       PS output: $psResult" -ForegroundColor Gray
        }
        if ($global:bashAvailable -and -not $baOk) {
            Write-Host "       SH expected=$Expected got=$(if($baDenied){'block'}else{'allow'})" -ForegroundColor Gray
            Write-Host "       SH output: $baResult" -ForegroundColor Gray
        }
    }
}

Write-Host "=== Git Guardrails Validation ===" -ForegroundColor Cyan
Write-Host ""

# --- Dangerous commands that MUST be blocked ---
Write-Host "--- Block tests (dangerous patterns) ---" -ForegroundColor Yellow
Test-Command "git push --force" "git push --force" "block"
Test-Command "git push -f" "git push -f" "block"
Test-Command "git reset --hard" "git reset --hard" "block"
Test-Command "git clean -fd" "git clean -fd" "block"
Test-Command "git clean -df" "git clean -df" "block"
Test-Command "git branch -D" "git branch -D" "block"
Test-Command "git checkout ." "git checkout ." "block"
Test-Command "git checkout -- file" "git checkout -- file" "block"
Test-Command "git restore ." "git restore ." "block"
Test-Command "git restore --staged ." "git restore --staged ." "block"
Test-Command "git rebase --skip" "git rebase --skip" "block"
Test-Command "git merge --abort" "git merge --abort" "block"

# --- Safe commands that MUST be allowed ---
Write-Host ""
Write-Host "--- Allow tests (safe patterns) ---" -ForegroundColor Yellow
Test-Command "git status" "git status" "allow"
Test-Command "git diff" "git diff" "allow"
Test-Command "git add file.txt" "git add file.txt" "allow"
Test-Command "git commit -m msg" "git commit -m msg" "allow"
Test-Command "git push origin main" "git push origin main" "allow"
Test-Command "git checkout -b feature" "git checkout -b feature" "allow"
Test-Command "git branch feature" "git branch feature" "allow"
Test-Command "git log" "git log" "allow"
Test-Command "git pull" "git pull" "allow"
Test-Command "git restore file.txt" "git restore file.txt" "allow"

# --- Edge cases ---
Write-Host ""
Write-Host "--- Edge cases ---" -ForegroundColor Yellow
Test-Command "git push --force-with-lease" "git push --force-with-lease" "allow"
Test-Command "git reset --soft HEAD^" "git reset --soft HEAD^" "allow"

Write-Host ""
Write-Host "=== Results: $passed passed, $failed failed ===" -ForegroundColor Cyan
if ($failed -gt 0) {
    exit 1
}
