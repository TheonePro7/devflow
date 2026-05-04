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

# ---- Step 4: Summary ----
Write-Host ""
Write-Host "=== devflow ready ===" -ForegroundColor Cyan
Write-Host "  phase 1:  beads + gitnexus initialized" -ForegroundColor Gray
Write-Host "  phase 2:  superpowers-* pipeline + tool injection" -ForegroundColor Gray
Write-Host "  on-demand: /autoresearch (if installed)" -ForegroundColor Gray
Write-Host ""
Write-Host "Start a dev task in Claude Code — devflow auto-triggers." -ForegroundColor Green
