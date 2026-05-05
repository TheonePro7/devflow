<#
.SYNOPSIS
    Initialize devflow workflow in a new project.
.DESCRIPTION
    Checks prerequisites, initializes beads, and builds gitnexus index.
#>

$ErrorActionPreference = "Stop"

Write-Host "=== devflow setup (Phase 1) ===" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: Check prerequisites ----
$missing = @()

if (-not (Get-Command "bd" -ErrorAction SilentlyContinue)) {
    $missing += "beads (bd) — install: go install github.com/gastownhall/beads/cmd/bd@latest"
}

if (-not (Get-Command "gitnexus" -ErrorAction SilentlyContinue)) {
    $missing += "gitnexus — install: npm install -g gitnexus"
}

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Missing prerequisites:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "       $_" }
    exit 1
}

Write-Host "[PASS] Prerequisites: beads + gitnexus" -ForegroundColor Green

# ---- Step 2: Init beads ----
Write-Host ""
Write-Host "--- beads init ---" -ForegroundColor Yellow
bd init 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[PASS] beads initialized" -ForegroundColor Green
} else {
    Write-Host "[WARN] beads init failed (maybe already initialized)" -ForegroundColor Yellow
}

# ---- Step 3: GitNexus analyze ----
Write-Host ""
Write-Host "--- gitnexus analyze ---" -ForegroundColor Yellow
gitnexus analyze . --force 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[PASS] gitnexus index built" -ForegroundColor Green
} else {
    Write-Host "[FAIL] gitnexus analyze failed — run 'npx gitnexus analyze . --force' manually" -ForegroundColor Red
}

# ---- Step 4: Seed docs/CONTEXT.md (if not exists) ----
Write-Host ""
Write-Host "--- seeding project docs ---" -ForegroundColor Yellow
$contextMd = Join-Path $PWD "docs\CONTEXT.md"
if (-not (Test-Path $contextMd)) {
    $null = New-Item -ItemType File -Path $contextMd -Force
    @"
# Project Context — Ubiquitous Language

## Project
<!-- TODO: describe what this project does -->

## Domain Glossary
<!-- TODO: add key terms and definitions -->
"@ | Set-Content -Path $contextMd
    Write-Host "[PASS] docs/CONTEXT.md seeded" -ForegroundColor Green
} else {
    Write-Host "[SKIP] docs/CONTEXT.md already exists" -ForegroundColor Gray
}

# ---- Step 5: Seed docs/adr/ (if empty) ----
$adrDir = Join-Path $PWD "docs\adr"
if (-not (Test-Path $adrDir)) {
    $null = New-Item -ItemType Directory -Path $adrDir -Force
    @"
# Architecture Decision Records

## Index

<!-- Add ADRs here sequentially -->
"@ | Set-Content -Path (Join-Path $adrDir "README.md")
    Write-Host "[PASS] docs/adr/ seeded" -ForegroundColor Green
} else {
    Write-Host "[SKIP] docs/adr/ already exists" -ForegroundColor Gray
}

# ---- Step 6: Seed docs/tdd/ (if empty) ----
$tddDir = Join-Path $PWD "docs\tdd"
if (-not (Test-Path $tddDir)) {
    $null = New-Item -ItemType Directory -Path $tddDir -Force
    Write-Host "[PASS] docs/tdd/ directory created" -ForegroundColor Green
    Write-Host "      (copy reference docs from devflow/docs/tdd/)" -ForegroundColor Gray
} else {
    Write-Host "[SKIP] docs/tdd/ already exists" -ForegroundColor Gray
}

# ---- Step 7: Check git guardrails hook ----
$guardrailsHook = Join-Path $PWD ".claude\hooks\guardrails-git.ps1"
if (-not (Test-Path $guardrailsHook)) {
    Write-Host "[WARN] .claude/hooks/guardrails-git.ps1 not found" -ForegroundColor Yellow
    Write-Host "       Copy from devflow skill directory to enable git safety." -ForegroundColor Gray
} else {
    Write-Host "[PASS] git guardrails hook present" -ForegroundColor Green
}

# ---- Step 8: Summary ----
Write-Host ""
Write-Host "=== devflow ready ===" -ForegroundColor Cyan
Write-Host "  phase 1:  beads + gitnexus + docs seeded + guardrails" -ForegroundColor Gray
Write-Host "  phase 2:  superpowers-* pipeline + grill + tool injection" -ForegroundColor Gray
Write-Host "  on-demand: /autoresearch (if installed)" -ForegroundColor Gray
Write-Host ""
Write-Host "Start a dev task in Claude Code — devflow auto-triggers." -ForegroundColor Green
