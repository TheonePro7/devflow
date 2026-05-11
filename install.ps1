<#
.SYNOPSIS
    One-command devflow installer for a project.
.DESCRIPTION
    Installs devflow tools (beads, gitnexus, autoresearch) and runs
    devflow init to scaffold the project. No repo cloning — devflow
    CLI is expected to be installed globally via pip:
      pip install devflow
    or run directly from source:
      python -m devflow.cli.main init

    Run this inside your project directory.
.USAGE
    cd your-project
    powershell -File path/to/devflow/install.ps1
    powershell -File path/to/devflow/install.ps1 --offline
    powershell -File path/to/devflow/install.ps1 --skip-autoresearch
.PARAMETER Offline
    Skip tool installation; assume prerequisites are already installed.
.PARAMETER SkipAutoresearch
    Skip autoresearch installation.
.PARAMETER DevflowSrc
    Path to devflow source directory. If not set, tries pip-installed
    devflow, then falls back to python -m devflow.cli.main.
#>

param(
    [switch]$Offline,
    [switch]$SkipAutoresearch,
    [string]$DevflowSrc = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=== devflow project installer ===" -ForegroundColor Cyan
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

# ---- Step 2: Locate devflow CLI ----
Write-Host ""
Write-Host "--- devflow CLI ---" -ForegroundColor Yellow

$devflowCmd = $null
if (-not [string]::IsNullOrEmpty($DevflowSrc)) {
    $devflowCmd = "python -m devflow.cli.main"
    $env:PYTHONPATH = $DevflowSrc
    Write-Host "[INFO] Using devflow source: $DevflowSrc" -ForegroundColor Gray
} elseif (($null -ne (Get-Command "devflow" -ErrorAction SilentlyContinue))) {
    $devflowCmd = "devflow"
    Write-Host "[PASS] devflow CLI found in PATH" -ForegroundColor Green
} else {
    try {
        python -c "import devflow; print('ok')" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $devflowCmd = "python -m devflow.cli.main"
            Write-Host "[PASS] devflow found via python -m" -ForegroundColor Green
        }
    } catch { }
}

if (-not $devflowCmd) {
    Write-Host "[INFO] devflow CLI not found. Install with:" -ForegroundColor Yellow
    Write-Host "       pip install devflow" -ForegroundColor Cyan
    Write-Host "  Or set -DevflowSrc to point to the devflow repository." -ForegroundColor Cyan
    Write-Host "  Continuing with tool installation only (run devflow init later)..." -ForegroundColor Yellow
}

# ---- Step 3: Install beads ----
Write-Host ""
Write-Host "--- beads ---" -ForegroundColor Yellow
$beadsOk = $false

if (-not $Offline) {
    if (-not (Get-Command "bd" -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] beads (bd) not found - installing via go..." -ForegroundColor Yellow
        try {
            go install github.com/gastownhall/beads/cmd/bd@latest 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + [Environment]::GetEnvironmentVariable("Path", "Machine")
                Write-Host "[PASS] beads installed" -ForegroundColor Green
                $beadsOk = $true
            } else {
                Write-Host "[FAIL] go install beads failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "[FAIL] beads install failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "[PASS] beads already installed" -ForegroundColor Green
        $beadsOk = $true
    }
} else {
    $beadsOk = (Get-Command "bd" -ErrorAction SilentlyContinue) -ne $null
    Write-Host "[SKIP] Offline mode - beads: $(if($beadsOk){ 'found' }else{ 'missing' })" -ForegroundColor Yellow
}

# ---- Step 4: Install gitnexus ----
Write-Host ""
Write-Host "--- gitnexus ---" -ForegroundColor Yellow
$gitnexusOk = $false

if (-not $Offline) {
    if (-not (Get-Command "gitnexus" -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] gitnexus not found - installing via npm..." -ForegroundColor Yellow
        try {
            npm install -g gitnexus 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[PASS] gitnexus installed" -ForegroundColor Green
                $gitnexusOk = $true
            } else {
                Write-Host "[FAIL] npm install gitnexus failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "[FAIL] gitnexus install failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "[PASS] gitnexus already installed" -ForegroundColor Green
        $gitnexusOk = $true
    }
} else {
    $gitnexusOk = (Get-Command "gitnexus" -ErrorAction SilentlyContinue) -ne $null
    Write-Host "[SKIP] Offline mode - gitnexus: $(if($gitnexusOk){ 'found' }else{ 'missing' })" -ForegroundColor Yellow
}

# ---- Step 5: Install autoresearch ----
if (-not $SkipAutoresearch) {
    Write-Host ""
    Write-Host "--- autoresearch ---" -ForegroundColor Yellow
    if (-not $Offline) {
        try {
            $npxCmd = if ($IsWindows -or $env:OS) { "npx.cmd" } else { "npx" }
            & $npxCmd --yes skills add uditgoenka/autoresearch --yes --claude 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[PASS] autoresearch installed" -ForegroundColor Green
            } else {
                Write-Host "[WARN] autoresearch install had issues" -ForegroundColor Yellow
                Write-Host "       Run manually: npx skills add uditgoenka/autoresearch" -ForegroundColor Gray
            }
        } catch {
            Write-Host "[WARN] autoresearch install failed: $_" -ForegroundColor Yellow
            Write-Host "       Run manually: npx skills add uditgoenka/autoresearch" -ForegroundColor Gray
        }
    } else {
        Write-Host "[SKIP] Offline mode - skip autoresearch install" -ForegroundColor Yellow
    }
}

# ---- Step 6: Run devflow init ----
Write-Host ""
Write-Host "--- project scaffold ---" -ForegroundColor Yellow

if ($devflowCmd) {
    $initCmd = "$devflowCmd init"
    if ($Offline) { $initCmd += " --offline" }
    try {
        Invoke-Expression $initCmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[PASS] devflow init complete" -ForegroundColor Green
        } else {
            Write-Host "[WARN] devflow init had issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARN] devflow init failed: $_" -ForegroundColor Yellow
        Write-Host "       Run manually: $devflowCmd init" -ForegroundColor Gray
    }
} else {
    Write-Host "[INFO] devflow CLI not available - scaffold manually:" -ForegroundColor Yellow
    Write-Host "       1. Install: pip install devflow" -ForegroundColor Cyan
    Write-Host "       2. Init:    devflow init" -ForegroundColor Cyan
}

# ---- Step 7: Summary ----
Write-Host ""
Write-Host "=== install complete ===" -ForegroundColor Cyan
Write-Host "  beads:       $(if($beadsOk){ '✅' }else{ '❌' })" -ForegroundColor Gray
Write-Host "  gitnexus:    $(if($gitnexusOk){ '✅' }else{ '⚠️' })" -ForegroundColor Gray
$arLabel = "attempted"
if ($SkipAutoresearch) { $arLabel = "skipped" }
Write-Host "  autoresearch: $arLabel" -ForegroundColor Gray
if ($devflowCmd) {
    Write-Host "  scaffold:    init complete" -ForegroundColor Gray
} else {
    Write-Host "  scaffold:    run 'devflow init' after installing CLI" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Open this project in Claude Code — devflow guides the pipeline." -ForegroundColor Green
