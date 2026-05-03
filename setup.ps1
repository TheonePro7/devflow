<#
.SYNOPSIS
    Initialize devflow workflow in a new project.
.DESCRIPTION
    Checks prerequisites, initializes beads, builds gitnexus index,
    and copies prompt templates to .claude/prompts/.
#>

$ErrorActionPreference = "Stop"
$DevflowDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== devflow setup ===" -ForegroundColor Cyan
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

# ---- Step 4: Copy prompts ----
Write-Host ""
Write-Host "--- prompts ---" -ForegroundColor Yellow
$TargetPromptDir = ".claude/prompts"
if (-not (Test-Path $TargetPromptDir)) {
    New-Item -ItemType Directory -Path $TargetPromptDir -Force | Out-Null
}
$SourcePromptDir = Join-Path $DevflowDir "prompts"
if (Test-Path $SourcePromptDir) {
    Copy-Item -Path (Join-Path $SourcePromptDir "*.md") -Destination $TargetPromptDir -Force
    Write-Host "[PASS] prompts copied to $TargetPromptDir" -ForegroundColor Green
} else {
    Write-Host "[WARN] prompts directory not found at $SourcePromptDir" -ForegroundColor Yellow
}

# ---- Step 5: Summary ----
Write-Host ""
Write-Host "=== devflow ready ===" -ForegroundColor Cyan
Write-Host "  globals:  tdd (mattpocock) + superpowers-* (14 skills)" -ForegroundColor Gray
Write-Host "  project:  beads + gitnexus + prompts" -ForegroundColor Gray
Write-Host ""
Write-Host "Start a dev task in Claude Code — devflow auto-triggers." -ForegroundColor Green
