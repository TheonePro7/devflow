<#
.SYNOPSIS
    One-command devflow installer with merge-mode setup.
.DESCRIPTION
    Checks prerequisites, clones devflow if missing, installs tools,
    runs setup with merge-mode flag.
    Designed to be run after: git clone https://github.com/TheonePro7/devflow.git
.USAGE
    cd your-project
    powershell -File path/to/devflow/install.ps1
    powershell -File path/to/devflow/install.ps1 --offline
    powershell -File path/to/devflow/install.ps1 -DevflowRepo https://github.com/TheonePro7/devflow.git
.PARAMETER DevflowDir
    Path to devflow directory. Default: ~/.claude/skills/devflow
.PARAMETER DevflowRepo
    Git URL for devflow repo. Default: https://github.com/TheonePro7/devflow.git
.PARAMETER GitProxy
    HTTP proxy for git clone. Default: none.
.PARAMETER Offline
    Skip git clone; assume devflow is already present.
.PARAMETER SkipAutoresearch
    Skip autoresearch installation.
#>

param(
    [string]$DevflowDir = "",
    [string]$DevflowRepo = "https://github.com/TheonePro7/devflow.git",
    [string]$GitProxy = "",
    [switch]$Offline,
    [switch]$SkipAutoresearch
)

$ErrorActionPreference = "Stop"
$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
if (-not $homeDir) { $homeDir = "~" }

if ([string]::IsNullOrEmpty($DevflowDir)) {
    $DevflowDir = Join-Path $homeDir ".claude\skills\devflow"
}

Write-Host "=== devflow installer ===" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: Check base dependencies ----
Write-Host "--- checking base dependencies ---" -ForegroundColor Yellow
$baseMissing = @()

if (-not (Get-Command "go" -ErrorAction SilentlyContinue)) {
    $baseMissing += "Go (https://go.dev/dl/) or: winget install GoLang.Go"
}
if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    $baseMissing += "Node.js >= 18 (https://nodejs.org/) or: winget install OpenJS.NodeJS"
}
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    $baseMissing += "Git (https://git-scm.com/) or: winget install Git.Git"
}

if ($baseMissing.Count -gt 0) {
    Write-Host "[MISS] Base dependencies not found:" -ForegroundColor Yellow
    foreach ($m in $baseMissing) { Write-Host "       $m" }
    Write-Host ""
    Write-Host "       Install these first, then re-run this installer." -ForegroundColor Cyan
    exit 1
}
Write-Host "[PASS] Go + Node.js + Git" -ForegroundColor Green

# ---- Step 2: Clone devflow (unless offline) ----
Write-Host ""
Write-Host "--- devflow skill ---" -ForegroundColor Yellow

if ($Offline.IsPresent) {
    if (-not (Test-Path $DevflowDir)) {
        Write-Host "[FAIL] --offline mode but devflow not found at:" -ForegroundColor Red
        Write-Host "       $DevflowDir" -ForegroundColor Red
        Write-Host "       Clone manually first:" -ForegroundColor Yellow
        Write-Host "       git clone $DevflowRepo `"$DevflowDir`"" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "[SKIP] Offline mode - using existing $DevflowDir" -ForegroundColor Yellow
}
else {
    if (Test-Path (Join-Path $DevflowDir "setup.ps1")) {
        Write-Host "[SKIP] devflow already installed at $DevflowDir" -ForegroundColor Yellow
    } else {
        Write-Host "[INFO] Cloning devflow to $DevflowDir ..." -ForegroundColor Yellow
        # Ensure parent directory exists
        $parentDir = Split-Path $DevflowDir -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        $gitArgs = @("clone", $DevflowRepo, "`"$DevflowDir`"")
        if (-not [string]::IsNullOrEmpty($GitProxy)) {
            $gitArgs = @("-c", "http.proxy=$GitProxy") + $gitArgs
            Write-Host "       Using proxy: $GitProxy" -ForegroundColor Gray
        }

        try {
            & "git" $gitArgs 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
            Write-Host "[PASS] devflow cloned" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL] Could not clone devflow: $_" -ForegroundColor Red
            Write-Host "       Clone manually: git clone $DevflowRepo `"$DevflowDir`"" -ForegroundColor Cyan
            exit 1
        }
    }
}

# ---- Step 3: Superpowers check ----
Write-Host ""
Write-Host "--- superpowers plugin ---" -ForegroundColor Yellow
$superpowersCheck = Join-Path $DevflowDir "scripts\check-superpowers.ps1"
if (Test-Path $superpowersCheck) {
    & $superpowersCheck
    if ($LASTEXITCODE -ne 0) {
        # Already printed the warning inside check-superpowers
    }
} else {
    Write-Host "[INFO] Run in Claude Code to complete setup:" -ForegroundColor Yellow
    Write-Host "       /plugin install superpowers@claude-plugins-official" -ForegroundColor Cyan
}

# ---- Step 4: Run setup ----
Write-Host ""
Write-Host "--- running setup ---" -ForegroundColor Yellow
$setupScript = Join-Path $DevflowDir "setup.ps1"
if (Test-Path $setupScript) {
    $setupArgs = @()
    if ($SkipAutoresearch) { $setupArgs += "--skip-autoresearch" }
    & $setupScript $setupArgs
} else {
    Write-Host "[FAIL] setup.ps1 not found at $setupScript" -ForegroundColor Red
    exit 1
}

# ---- Step 5: Post-install instructions ----
Write-Host ""
Write-Host "=== Install complete ===" -ForegroundColor Cyan
Write-Host "  devflow installed at: $DevflowDir" -ForegroundColor Gray
Write-Host "  To complete setup, open this project in Claude Code and:" -ForegroundColor Gray
Write-Host "  1. Claude Code will auto-detect Phase 1 and finalize setup" -ForegroundColor Gray
Write-Host "  2. If superpowers is missing, type: /plugin install superpowers@claude-plugins-official" -ForegroundColor Cyan
Write-Host "  3. Start a development task — devflow guides the pipeline" -ForegroundColor Gray
Write-Host ""
Write-Host "Happy coding!" -ForegroundColor Green
