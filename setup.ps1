<#
.SYNOPSIS
    Initialize devflow workflow in a project (Phase 1 Setup).
.DESCRIPTION
    Auto-installs tools, initializes beads + gitnexus, seeds docs, registers guardrails.
    Supports merge mode (default) — detects and merges existing configs.
.USAGE
    .\setup.ps1             # Merge mode (idempotent)
    .\setup.ps1 --fresh     # Fresh install (overwrite)
    .\setup.ps1 --skip-autoresearch
#>

param(
    [switch]$Fresh,
    [switch]$SkipAutoresearch,
    [switch]$WithDesigner
)

$ErrorActionPreference = "Stop"
$mergeMode = -not $Fresh.IsPresent

Write-Host "=== devflow setup (Phase 1) ===" -ForegroundColor Cyan
if ($mergeMode) {
    Write-Host "  mode: merge (idempotent) — existing configs will be preserved and extended." -ForegroundColor Gray
} else {
    Write-Host "  mode: fresh — existing configs may be overwritten." -ForegroundColor Yellow
}
Write-Host ""

# ---- Step 1: Check & install prerequisites ----
$missing = @()

if (-not (Get-Command "bd" -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] beads (bd) not found - auto-installing..." -ForegroundColor Yellow
    try {
        go install github.com/gastownhall/beads/cmd/bd@latest 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + [Environment]::GetEnvironmentVariable("Path", "Machine")
        if (-not (Get-Command "bd" -ErrorAction SilentlyContinue)) {
            $missing += "beads (bd) - installed but not in PATH. Add Go bin to PATH or run: go install github.com/gastownhall/beads/cmd/bd@latest"
        }
    } catch {
        $missing += "beads (bd) - install failed: $($_.Exception.Message). Manual: go install github.com/gastownhall/beads/cmd/bd@latest"
    }
}

if (-not (Get-Command "gitnexus" -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] gitnexus not found - auto-installing..." -ForegroundColor Yellow
    try {
        npm install -g gitnexus 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
        if (-not (Get-Command "gitnexus" -ErrorAction SilentlyContinue)) {
            $missing += "gitnexus - npm install succeeded but command not found. Try: npx gitnexus"
        }
    } catch {
        $missing += "gitnexus - install failed: $($_.Exception.Message). Manual: npm install -g gitnexus"
    }
}

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Some tools could not be auto-installed:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host "[PASS] Prerequisites: beads + gitnexus" -ForegroundColor Green

$gitnexusOk = $false

# ---- Step 2: Init beads ----
Write-Host ""
Write-Host "--- beads init ---" -ForegroundColor Yellow
if (Test-Path ".beads") {
    Write-Host "[SKIP] .beads/ already exists - running bd doctor to verify..." -ForegroundColor Yellow
    bd doctor 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] beads OK (bd doctor passed)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] beads issues found - run 'bd doctor' manually" -ForegroundColor Yellow
    }
} else {
    bd init 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] beads initialized" -ForegroundColor Green
    } else {
        Write-Host "[WARN] beads init failed" -ForegroundColor Yellow
    }
}

# ---- Step 3: GitNexus analyze ----
Write-Host ""
Write-Host "--- gitnexus analyze ---" -ForegroundColor Yellow
$ignoreGitnexus = $false
if (Test-Path ".gitnexus") {
    Write-Host "[SKIP] .gitnexus/ already exists - skipping analyze (use --fresh to rebuild)" -ForegroundColor Yellow
    $gitnexusOk = $true
    $ignoreGitnexus = $true
}
if (-not $ignoreGitnexus) {
    gitnexus analyze . --force 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $gitnexusOk = $true
        Write-Host "[PASS] gitnexus index built" -ForegroundColor Green
    } else {
        Write-Host "[WARN] gitnexus analyze failed (exit code $LASTEXITCODE) - non-fatal" -ForegroundColor Yellow
    }
}

# ---- Step 4: Settings.json merge ----
Write-Host ""
Write-Host "--- settings.json ---" -ForegroundColor Yellow
if ($mergeMode -and (Test-Path ".claude/settings.json")) {
    & ".\scripts\merge-settings.ps1"
} elseif ($mergeMode) {
    & ".\scripts\merge-settings.ps1"
} else {
    # Fresh mode - just write defaults
    & ".\scripts\merge-settings.ps1"
}
Write-Host "[PASS] settings.json configured" -ForegroundColor Green

# ---- Step 5: Guardrails hooks ----
Write-Host ""
Write-Host "--- guardrails hooks ---" -ForegroundColor Yellow
$hookDir = ".claude/hooks"
if (-not (Test-Path $hookDir)) {
    New-Item -ItemType Directory -Path $hookDir -Force | Out-Null
}

$guardrailsPs1 = Join-Path $hookDir "guardrails-git.ps1"
$devflowGuardrailsPs1 = Join-Path $PSScriptRoot ".claude/hooks/guardrails-git.ps1"

if (-not (Test-Path $guardrailsPs1) -or -not $mergeMode) {
    if (Test-Path $devflowGuardrailsPs1) {
        Copy-Item $devflowGuardrailsPs1 $guardrailsPs1 -Force
        Write-Host "[PASS] guardrails-git.ps1 installed" -ForegroundColor Green
    } else {
        Write-Host "[WARN] guardrails-git.ps1 not found in devflow" -ForegroundColor Yellow
    }
} else {
    # Existing guardrails found - merge patterns
    if (Test-Path ".\scripts\merge-guardrails.ps1") {
        & ".\scripts\merge-guardrails.ps1"
    } else {
        Write-Host "[SKIP] merge-guardrails.ps1 not found" -ForegroundColor Yellow
    }
}

$guardrailsSh = Join-Path $hookDir "guardrails-git.sh"
$devflowGuardrailsSh = Join-Path $PSScriptRoot ".claude/hooks/guardrails-git.sh"
if ((-not (Test-Path $guardrailsSh) -or -not $mergeMode) -and (Test-Path $devflowGuardrailsSh)) {
    Copy-Item $devflowGuardrailsSh $guardrailsSh -Force
    Write-Host "[PASS] guardrails-git.sh installed" -ForegroundColor Green
} elseif (-not (Test-Path $guardrailsSh)) {
    Write-Host "[SKIP] guardrails-git.sh not available" -ForegroundColor Yellow
}

# ---- Step 5.5: Create .devflow/ state directory ----
Write-Host ""
Write-Host "--- .devflow/ state directory ---" -ForegroundColor Yellow
$devflowDir = ".devflow"
if (-not (Test-Path $devflowDir)) {
    $null = New-Item -ItemType Directory -Path $devflowDir -Force
    Write-Host "[PASS] $devflowDir/ created" -ForegroundColor Green
} else {
    Write-Host "[SKIP] $devflowDir/ already exists" -ForegroundColor Yellow
}
$stateFile = Join-Path $devflowDir "state"
if (-not (Test-Path $stateFile)) {
    $initialState = @{
        phase = 0
        step = ""
        feature = ""
        prd = ""
        blocker = ""
        updatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json -Compress
    $initialState | Out-File $stateFile -Encoding utf8
    Write-Host "[PASS] .devflow/state initialized" -ForegroundColor Green
} else {
    Write-Host "[SKIP] .devflow/state already exists" -ForegroundColor Yellow
}

# ---- Step 6: Seed docs/ with merge ----
Write-Host ""
Write-Host "--- seeding docs/ ---" -ForegroundColor Yellow

# CONTEXT.md
$contextMd = "docs/CONTEXT.md"
if (Test-Path $contextMd) {
    if ($mergeMode) {
        if (Test-Path ".\scripts\merge-docs.ps1") {
            & ".\scripts\merge-docs.ps1"
        } else {
            Write-Host "[SKIP] merge-docs.ps1 not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[FRESH] overwriting $contextMd" -ForegroundColor Yellow
        # Re-seed (same content as below)
    }
}

if (-not (Test-Path $contextMd)) {
    $null = New-Item -ItemType File -Path $contextMd -Force
    @"
# Project Context - Ubiquitous Language

## Project
<!-- TODO: describe what this project does -->

## Domain Glossary
<!-- TODO: add key terms and definitions -->
"@ | Set-Content -Path $contextMd
    Write-Host "[PASS] docs/CONTEXT.md seeded" -ForegroundColor Green
}

# ADR
$adrDir = "docs/adr"
if (Test-Path $adrDir) {
    if (-not $mergeMode) {
        Write-Host "[FRESH] docs/adr/ exists but --fresh set" -ForegroundColor Yellow
    }
}
if (-not (Test-Path $adrDir)) {
    $null = New-Item -ItemType Directory -Path $adrDir -Force
    @"
# Architecture Decision Records

Each ADR (Architecture Decision Record) captures a decision:
- **Context** - what problem or constraint drove the decision
- **Decision** - what was chosen and why alternatives were rejected
- **Consequences** - what tradeoffs, migrations, or follow-up work result

## ADR Index

<!-- Add new ADRs below -->
"@ | Set-Content -Path (Join-Path $adrDir "README.md")
    Write-Host "[PASS] docs/adr/ seeded" -ForegroundColor Green
}

# TDD
$tddDir = "docs/tdd"
if (Test-Path $tddDir) {
    $existingTdd = Get-ChildItem "$tddDir/*.md" -ErrorAction SilentlyContinue
    if ($existingTdd.Count -gt 0 -and $mergeMode) {
        Write-Host "[SKIP] docs/tdd/ already has content - user modifications respected" -ForegroundColor Yellow
    } elseif ($existingTdd.Count -eq 0 -or -not $mergeMode) {
        @"
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** - tests should verify outcomes, not internal details
2. **Write tests before code** - TDD cycle: Red -> Green -> Refactor
3. **One assertion per test** - each test should verify one behavior
4. **Tests are documentation** - a good test suite describes how the system works

## Coverage Goals

- Unit tests: 90%+ coverage on business logic
- Integration tests: critical paths only
- E2E tests: happy path + top 3 error scenarios
"@ | Out-File "$tddDir/testing-philosophy.md" -Encoding utf8
        Write-Host "[PASS] docs/tdd/ seeded" -ForegroundColor Green
    }
} else {
    $null = New-Item -ItemType Directory -Path $tddDir -Force
    @"
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** - tests should verify outcomes, not internal details
2. **Write tests before code** - TDD cycle: Red -> Green -> Refactor
3. **One assertion per test** - each test should verify one behavior
4. **Tests are documentation** - a good test suite describes how the system works

## Coverage Goals

- Unit tests: 90%+ coverage on business logic
- Integration tests: critical paths only
- E2E tests: happy path + top 3 error scenarios
"@ | Out-File "$tddDir/testing-philosophy.md" -Encoding utf8
    Write-Host "[PASS] docs/tdd/ seeded" -ForegroundColor Green
}

# ---- Step 7: .gitignore merge ----
Write-Host ""
Write-Host "--- .gitignore ---" -ForegroundColor Yellow
if (Test-Path ".\scripts\merge-gitignore.ps1") {
    & ".\scripts\merge-gitignore.ps1"
} else {
    Write-Host "[SKIP] merge-gitignore.ps1 not found" -ForegroundColor Yellow
}

# ---- Step 8: Install autoresearch (unless opted out) ----
if ($SkipAutoresearch -or $env:DEVFLOW_NO_AUTORESEARCH -eq "1") {
    Write-Host ""
    Write-Host "--- autoresearch ---" -ForegroundColor Yellow
    Write-Host "[SKIP] opted out via flag or DEVFLOW_NO_AUTORESEARCH env var" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "--- autoresearch install ---" -ForegroundColor Yellow
    $skillsCmd = Get-Command "skills" -ErrorAction SilentlyContinue
    if ($skillsCmd) {
        npx skills add uditgoenka/autoresearch 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[PASS] autoresearch installed" -ForegroundColor Green
            Write-Host "       Auto-optimization at probe/scenario/fix/security gates." -ForegroundColor Gray
            Write-Host "       Disable: `$env:DEVFLOW_NO_AUTORESEARCH=1" -ForegroundColor Gray
        } else {
            Write-Host "[WARN] autoresearch install failed" -ForegroundColor Yellow
            Write-Host "       Run manually: npx skills add uditgoenka/autoresearch" -ForegroundColor Gray
        }
    } else {
        Write-Host "[WARN] npx skills not available - install autoresearch manually:" -ForegroundColor Yellow
        Write-Host "       npx skills add uditgoenka/autoresearch" -ForegroundColor Gray
    }
}

# ---- Optional: Auto-Designer generators ----
if ($WithDesigner) {
    Write-Host ""
    Write-Host "--- auto-designer generators ---" -ForegroundColor Yellow
    & ".\scripts\auto-designer.ps1" -Install openui 2>&1
}

# ---- Step 9: Superpowers check ----
Write-Host ""
Write-Host "--- superpowers check ---" -ForegroundColor Yellow
if (Test-Path ".\scripts\check-superpowers.ps1") {
    & ".\scripts\check-superpowers.ps1"
} else {
    Write-Host "[SKIP] check-superpowers.ps1 not found" -ForegroundColor Yellow
}

# ---- Step 10: Summary ----
Write-Host ""
Write-Host "=== devflow ready ===" -ForegroundColor Cyan
if ($gitnexusOk) {
    Write-Host "  phase 1:  beads + gitnexus + docs + guardrails + autoresearch + merge helpers" -ForegroundColor Gray
} else {
    Write-Host "  phase 1:  beads + docs + guardrails + autoresearch (gitnexus: DEGRADED)" -ForegroundColor Yellow
    Write-Host "            fix: run 'gitnexus analyze . --force' in native PowerShell" -ForegroundColor Gray
}
Write-Host "  scripts:   merge-settings, merge-guardrails, merge-gitignore, merge-docs, check-superpowers" -ForegroundColor Gray
Write-Host "  merge:     existing configs detected and extended (default mode)" -ForegroundColor Gray
Write-Host "  phase 2:   superpowers-* pipeline + grill + 4 autoresearch gates" -ForegroundColor Gray
Write-Host "  opt-out:   `$env:DEVFLOW_NO_AUTORESEARCH=1  (disable all auto gates)" -ForegroundColor Gray
Write-Host ""
Write-Host "Start a dev task in Claude Code - devflow auto-triggers." -ForegroundColor Green
