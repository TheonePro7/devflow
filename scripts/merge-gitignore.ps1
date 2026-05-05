<#
.SYNOPSIS
    Merge devflow-required entries into .gitignore.
.DESCRIPTION
    For each required entry, checks if it exists in .gitignore (exact line match).
    Appends only missing entries. Idempotent.
.PARAMETER TargetPath
    Path to .gitignore. Default: .gitignore
.PARAMETER DryRun
    If set, show what would be added without writing.
.EXAMPLE
    .\scripts\merge-gitignore.ps1
    .\scripts\merge-gitignore.ps1 -DryRun
#>

param(
    [string]$TargetPath = ".gitignore",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Entries devflow needs in .gitignore (order preserved)
$required = @(
    ".gitnexus/",
    ".beads/",
    ".dolt/",
    "*.db",
    ".beads-credential-key",
    ".claude/settings.local.json"
)

$existing = @()
if (Test-Path $TargetPath) {
    $existing = Get-Content $TargetPath
}

$missing = @()
foreach ($entry in $required) {
    $found = $false
    foreach ($line in $existing) {
        if ($entry -eq $line.Trim()) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $missing += $entry
    }
}

if ($missing.Count -eq 0) {
    Write-Host "[OK] .gitignore already up to date." -ForegroundColor Green
    return
}

if ($DryRun) {
    Write-Host "=== DRY RUN — Would append to $TargetPath ===" -ForegroundColor Cyan
    foreach ($e in $missing) { Write-Host "  + $e" -ForegroundColor Green }
    return
}

foreach ($entry in $missing) {
    Add-Content $TargetPath -Value $entry
}

Write-Host "[OK] Appended $($missing.Count) missing entry/entries to $TargetPath" -ForegroundColor Green
foreach ($e in $missing) { Write-Host "  + $e" -ForegroundColor Green }
