<#
.SYNOPSIS
    Check if superpowers plugin is fully installed.
.DESCRIPTION
    Verifies all 7 superpowers skill directories exist under ~/.claude/skills/.
    Returns exit code 0 if all present, 1 if any missing.
.PARAMETER Quiet
    If set, only output warnings when skills are missing (no "OK" messages).
.EXAMPLE
    .\scripts\check-superpowers.ps1
    .\scripts\check-superpowers.ps1 -Quiet
#>

param(
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
if (-not $homeDir) { $homeDir = "~" }

$superpowersSkills = @(
    "superpowers-brainstorming",
    "superpowers-writing-plans",
    "superpowers-using-git-worktrees",
    "superpowers-subagent-driven-development",
    "superpowers-requesting-code-review",
    "superpowers-finishing-a-development-branch",
    "superpowers-test-driven-development"
)

$allPresent = $true
$presentCount = 0
$missingCount = 0

foreach ($skill in $superpowersSkills) {
    $skillPath = Join-Path $homeDir ".claude\skills\$skill"
    if (Test-Path $skillPath) {
        $presentCount++
        if (-not $Quiet) {
            Write-Host "[OK] $skill" -ForegroundColor Green
        }
    } else {
        $missingCount++
        $allPresent = $false
        Write-Host "[MISS] $skill" -ForegroundColor Yellow
    }
}

if ($allPresent) {
    if (-not $Quiet) {
        Write-Host "[OK] All $presentCount superpowers skills present." -ForegroundColor Green
    }
    return $true
} else {
    Write-Host ""
    Write-Host "[WARN] superpowers plugin not fully installed ($missingCount missing)." -ForegroundColor Yellow
    Write-Host "       Phase 2 requires superpowers. Run in Claude Code:" -ForegroundColor Yellow
    Write-Host "       /plugin install superpowers@claude-plugins-official" -ForegroundColor Cyan
    return $false
}
