<#
.SYNOPSIS
    Detect existing guardrails patterns and merge (diff+append) devflow's patterns.
.DESCRIPTION
    Reads existing .claude/hooks/guardrails-git.ps1, parses the $dangerous array,
    diffs with devflow's canonical pattern list, appends only missing patterns.
    Idempotent — safe to run multiple times.
.PARAMETER TargetPath
    Path to the guardrails PS1 file. Default: .claude/hooks/guardrails-git.ps1
.PARAMETER DryRun
    If set, show what would change without writing.
.EXAMPLE
    .\scripts\merge-guardrails.ps1
    .\scripts\merge-guardrails.ps1 -DryRun
#>

param(
    [string]$TargetPath = ".claude/hooks/guardrails-git.ps1",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Devflow's canonical dangerous patterns for PowerShell
$devflowPatterns = @(
    'git push --force(?![-\w])',
    'git push -f(?![-\w])',
    'git reset --hard(?![-\w])',
    'git clean -fd(?![-\w])',
    'git clean -df(?![-\w])',
    'git branch -D(?![-\w])',
    'git checkout \.',
    'git checkout --',
    'git restore \.',
    'git restore --staged \.',
    'git rebase --skip(?![-\w])',
    'git merge --abort(?![-\w])'
)

function Extract-ExistingPatterns {
    <#
    .SYNOPSIS
        Parse the $dangerous array from an existing guardrails script.
        Returns empty array if no patterns found or file doesn't exist.
    #>
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    $content = Get-Content $Path -Raw
    if (-not $content) { return @() }

    $patterns = @()

    # Match the $dangerous = @( ... ) block
    # Pattern matches lines inside a @() block that contain quoted strings
    $inArray = $false
    foreach ($line in (Get-Content $Path)) {
        $trimmed = $line.Trim()

        if ($trimmed -match '^\$dangerous\s*=') {
            $inArray = $true
            continue
        }

        if ($inArray) {
            if ($trimmed -eq ')') { break }
            # Extract quoted pattern: 'pattern' or "pattern"
            if ($trimmed -match "['""](.+)['""]") {
                $patterns += $matches[1]
            }
        }
    }

    return $patterns
}

function Merge-Guardrails {
    <#
    .SYNOPSIS
        Reads existing guardrails, extracts patterns, appends missing devflow patterns.
    #>
    param(
        [string]$Path,
        [bool]$DryRun
    )

    $existingPatterns = Extract-ExistingPatterns -Path $Path

    if ($existingPatterns.Count -eq 0) {
        if (-not (Test-Path $Path)) {
            Write-Host "[SKIP] No existing guardrails at $Path — nothing to merge." -ForegroundColor Yellow
            return
        }
        # File exists but couldn't parse patterns — reinstall is safer
        Write-Host "[WARN] Could not parse $dangerous array from $Path" -ForegroundColor Yellow
        Write-Host "       Recommended: reinstall guardrails via setup script." -ForegroundColor Yellow
        return
    }

    # Diff: find patterns in devflow list that are NOT in existing
    $missingPatterns = @()
    foreach ($dfPattern in $devflowPatterns) {
        $found = $false
        foreach ($exPattern in $existingPatterns) {
            if ($dfPattern -eq $exPattern) {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $missingPatterns += $dfPattern
        }
    }

    if ($missingPatterns.Count -eq 0) {
        Write-Host "[OK] Guardrails already up to date ($($existingPatterns.Count) patterns)." -ForegroundColor Green
        return
    }

    # Append missing patterns to the file
    $content = Get-Content $Path -Raw

    if ($DryRun) {
        Write-Host "=== DRY RUN — Would append to $Path ===" -ForegroundColor Cyan
        Write-Host "Existing patterns: $($existingPatterns.Count)" -ForegroundColor Gray
        Write-Host "Missing patterns: $($missingPatterns.Count)" -ForegroundColor Yellow
        foreach ($p in $missingPatterns) {
            Write-Host "  + $p" -ForegroundColor Green
        }
        return
    }

    # Find the last pattern line before the closing ')'
    $lines = Get-Content $Path
    $lastPatternLine = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $trimmed = $lines[$i].Trim()
        if ($trimmed -match "['""].+['""]") {
            $lastPatternLine = $i
        }
        if ($trimmed -eq ')') {
            break
        }
    }

    if ($lastPatternLine -ge 0) {
        # Insert new patterns after the last existing pattern
        $indent = $lines[$lastPatternLine] -replace '[^\s].*', ''
        $newLines = @()
        foreach ($p in $missingPatterns) {
            $newLines += "$indent'$p'"
        }
        # Insert after last pattern line (before the closing ')')
        $insertAt = $lastPatternLine + 1

        # Check if the next line after lastPatternLine is already ')'
        $combinedLines = @()
        for ($i = 0; $i -le $lastPatternLine; $i++) {
            $combinedLines += $lines[$i]
        }
        foreach ($nl in $newLines) {
            $combinedLines += $nl
        }
        for ($i = $lastPatternLine + 1; $i -lt $lines.Count; $i++) {
            $combinedLines += $lines[$i]
        }

        $combinedLines -join "`r`n" | Out-File $Path -Encoding utf8 -NoNewline
        Write-Host "[OK] Appended $($missingPatterns.Count) missing pattern(s) to $Path" -ForegroundColor Green
        foreach ($p in $missingPatterns) {
            Write-Host "  + $p" -ForegroundColor Green
        }
    }
}

# --- Main ---
Merge-Guardrails -Path $TargetPath -DryRun $DryRun.IsPresent
