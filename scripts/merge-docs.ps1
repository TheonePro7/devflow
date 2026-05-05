<#
.SYNOPSIS
    Merge devflow seed docs into existing docs/ with safe merge strategies.
.DESCRIPTION
    Three merge operations:
    1. CONTEXT.md - appends missing glossary terms only
    2. ADR README.md - appends missing ADR index entries only
    3. TDD docs/ - writes if not exists, skips if exists
.PARAMETER DryRun
    If set, show what would change without writing.
.EXAMPLE
    .\scripts\merge-docs.ps1
    .\scripts\merge-docs.ps1 -DryRun
#>

param([switch]$DryRun)

$ErrorActionPreference = "Stop"

# ---- CONTEXT.md merge ----
function Merge-ContextMd {
    param($DryRun)
    $path = "docs/CONTEXT.md"
    if (-not (Test-Path $path)) {
        Write-Host "[SKIP] $path does not exist - seed via setup first." -ForegroundColor Yellow
        return
    }

    # Seed glossary terms (key = term heading, value = description line)
    $seedTerms = [ordered]@{
        "beads" = "Dolt-backed issue tracker. Hierarchical IDs (bd-xxx.y), dependency management, status tracking."
        "gitnexus" = "Code knowledge graph. Builds symbol index from repo for context/impact/query."
        "Plan-grill" = "HITL gate between brainstorming and writing-plans. Challenges design with CONTEXT.md + ADR + gitnexus."
        "PRD->beads" = "Auto-parses '## Task:' headings from design docs, creates beads issues with dependencies."
        "Git guardrails" = "PreToolUse hook. Blocks dangerous git commands (force push, hard reset, clean -fd, branch -D, checkout .)."
        "Merge semantics" = "Install scripts detect existing config and incrementally append rather than overwrite."
        "Idempotent" = "Re-running install scripts produces the same result without duplicating or destroying config."
    }

    $existingTerms = @{}
    foreach ($line in (Get-Content $path)) {
        if ($line -match '^###\s+(.+)$') { $existingTerms[$matches[1].Trim()] = $true }
    }

    $missingTerms = [ordered]@{}
    foreach ($term in $seedTerms.Keys) {
        if (-not $existingTerms.ContainsKey($term)) { $missingTerms[$term] = $seedTerms[$term] }
    }

    if ($missingTerms.Count -eq 0) {
        Write-Host "[OK] CONTEXT.md terms already up to date." -ForegroundColor Green
        return
    }

    if ($DryRun) {
        Write-Host "=== DRY RUN - Would append to $path ===" -ForegroundColor Cyan
        foreach ($term in $missingTerms.Keys) { Write-Host "  + ### $term" -ForegroundColor Green }
        return
    }

    $insertBefore = "## Architecture Decisions"
    $lines = Get-Content $path
    $insertAt = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape($insertBefore)) { $insertAt = $i; break }
    }

    $newLines = @()
    for ($i = 0; $i -lt $insertAt; $i++) { $newLines += $lines[$i] }
    foreach ($term in $missingTerms.Keys) {
        $newLines += "### $term"
        $newLines += $seedTerms[$term]
        $newLines += ""
    }
    for ($i = $insertAt; $i -lt $lines.Count; $i++) { $newLines += $lines[$i] }

    $newLines -join "`r`n" | Out-File $path -Encoding utf8
    Write-Host "[OK] Appended $($missingTerms.Count) term(s) to CONTEXT.md" -ForegroundColor Green
    foreach ($term in $missingTerms.Keys) { Write-Host "  + ### $term" -ForegroundColor Green }
}

# ---- ADR README.md merge ----
function Merge-AdrReadme {
    param($DryRun)
    $readmePath = "docs/adr/README.md"
    if (-not (Test-Path $readmePath)) {
        Write-Host "[SKIP] $readmePath does not exist - seed via setup first." -ForegroundColor Yellow
        return
    }

    $adrFiles = Get-ChildItem "docs/adr/" -Filter "*.md" | Where-Object { $_.Name -ne "README.md" } | Sort-Object Name
    if ($adrFiles.Count -eq 0) { Write-Host "[SKIP] No ADR files to index." -ForegroundColor Yellow; return }

    $existingLinks = @{}
    foreach ($line in (Get-Content $readmePath)) {
        if ($line -match '\[([^\]]+)\]\(([^)]+)\)') { $existingLinks[$matches[2]] = $true }
    }

    $missingFiles = @()
    foreach ($file in $adrFiles) {
        if (-not $existingLinks.ContainsKey($file.Name)) { $missingFiles += $file }
    }

    if ($missingFiles.Count -eq 0) { Write-Host "[OK] ADR index already up to date." -ForegroundColor Green; return }

    if ($DryRun) {
        Write-Host "=== DRY RUN - Would append to $readmePath ===" -ForegroundColor Cyan
        foreach ($f in $missingFiles) { Write-Host "  + $($f.Name)" -ForegroundColor Green }
        return
    }

    Add-Content $readmePath -Value ""
    foreach ($f in $missingFiles) { Add-Content $readmePath -Value "- [$($f.Name)]($($f.Name))" }
    Write-Host "[OK] Appended $($missingFiles.Count) ADR entry/entries" -ForegroundColor Green
    foreach ($f in $missingFiles) { Write-Host "  + $($f.Name)" -ForegroundColor Green }
}

# ---- TDD docs merge ----
function Merge-TddDocs {
    param($DryRun)
    $tddDir = "docs/tdd"
    $tddTemplate = "docs/tdd/testing-philosophy.md"

    if (Test-Path $tddDir) {
        $existing = Get-ChildItem "$tddDir/*.md" -ErrorAction SilentlyContinue
        if ($existing.Count -gt 0) {
            Write-Host "[SKIP] TDD docs already exist - user modifications respected." -ForegroundColor Yellow
            return
        }
    }

    if ($DryRun) {
        Write-Host "=== DRY RUN - Would create $tddTemplate ===" -ForegroundColor Cyan
        return
    }

    if (-not (Test-Path $tddDir)) { New-Item -ItemType Directory -Path $tddDir -Force | Out-Null }

    @"
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** - tests should verify outcomes, not internal details
2. **Write tests before code** - TDD cycle: Red -> Green -> Refactor
3. **One assertion per test** - each test should verify one behavior
4. **Tests are documentation** - a good test suite describes how the system works

## Test Structure

describe('feature')
  describe('scenario')
    it('should behave as expected')

## Coverage Goals

- Unit tests: 90%+ coverage on business logic
- Integration tests: critical paths only
- E2E tests: happy path + top 3 error scenarios
"@ | Out-File $tddTemplate -Encoding utf8

    Write-Host "[OK] Created $tddTemplate" -ForegroundColor Green
}

# ---- Main ----
Write-Host "=== Docs Merge ===" -ForegroundColor Cyan
Merge-ContextMd -DryRun $DryRun.IsPresent
Merge-AdrReadme -DryRun $DryRun.IsPresent
Merge-TddDocs -DryRun $DryRun.IsPresent
