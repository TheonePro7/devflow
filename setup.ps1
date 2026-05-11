<#
.SYNOPSIS
    Initialize devflow scaffold in the current project directory.
.DESCRIPTION
    Generates the devflow project scaffold directly — no external
    repo copy needed. Creates:
      - .devflow/          state tracking
      - .beads/            issue tracking (via bd init)
      - .gitnexus/         code graph index (via Docker or native)
      - .claude/settings.json  hooks registration
      - .claude/hooks/     guardrails + session hooks
      - docs/              seed documentation (CONTEXT.md, ADR, TDD)
      - docs/prd/          PRD output directory
      - docs/ux/           UI design output directory
      - docs/superpowers/specs/  design specs directory
      - .gitignore         sensible defaults

    Should be run from the project root directory.
.USAGE
    .\setup.ps1             # Merge mode (idempotent)
    .\setup.ps1 --fresh     # Fresh install (overwrite existing)
    .\setup.ps1 --skip-autoresearch
.PARAMETER Fresh
    Overwrite existing configs instead of merging.
.PARAMETER SkipAutoresearch
    Skip autoresearch installation.
#>

param(
    [switch]$Fresh,
    [switch]$SkipAutoresearch
)

$ErrorActionPreference = "Stop"
$mergeMode = -not $Fresh.IsPresent

Write-Host "=== devflow setup (project scaffold) ===" -ForegroundColor Cyan
if ($mergeMode) {
    Write-Host "  mode: merge — existing configs will be preserved." -ForegroundColor Gray
} else {
    Write-Host "  mode: fresh — existing configs will be overwritten." -ForegroundColor Yellow
}
Write-Host ""

# ---- Step 1: Create .devflow/ state directory ----
Write-Host "--- .devflow/ state ---" -ForegroundColor Yellow
$devflowDir = ".devflow"
if (-not (Test-Path $devflowDir) -or -not $mergeMode) {
    $null = New-Item -ItemType Directory -Path $devflowDir -Force
    $initialState = @{
        phase = 1
        step = ""
        feature = ""
        prd = ""
        blocker = ""
        gate_probe = "pending"
        gate_scenario = "pending"
        gate_fix = "pending"
        gate_security = "pending"
        updatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json -Compress
    $initialState | Out-File (Join-Path $devflowDir "state") -Encoding utf8
    Write-Host "[PASS] .devflow/state initialized" -ForegroundColor Green
} else {
    Write-Host "[SKIP] .devflow/state already exists" -ForegroundColor Yellow
}

# ---- Step 2: Init beads ----
Write-Host ""
Write-Host "--- beads init ---" -ForegroundColor Yellow
$beadsOk = $false
if (Test-Path ".beads") {
    if ($mergeMode) {
        Write-Host "[SKIP] .beads/ already exists" -ForegroundColor Yellow
        $beadsOk = $true
    } else {
        Write-Host "[FRESH] re-initializing beads..." -ForegroundColor Yellow
        bd init --force 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $beadsOk = $true }
    }
} else {
    bd init 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] beads initialized" -ForegroundColor Green
        $beadsOk = $true
    } else {
        Write-Host "[WARN] beads init failed — run 'bd init' manually" -ForegroundColor Yellow
    }
}

# ---- Step 3: GitNexus analyze ----
Write-Host ""
Write-Host "--- gitnexus analyze ---" -ForegroundColor Yellow
$gitnexusOk = $false
if (Test-Path ".gitnexus" -and $mergeMode) {
    Write-Host "[SKIP] .gitnexus/ already exists" -ForegroundColor Yellow
    $gitnexusOk = $true
} else {
    $dockerAvailable = $false
    try {
        $null = docker ps 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $dockerAvailable = $true }
    } catch { }

    if ($dockerAvailable) {
        Write-Host "[INFO] Docker detected — using gitnexus Docker image..." -ForegroundColor Gray
        $repoPath = (Get-Location).Path
        docker run --rm -v "${repoPath}:/repo" --user root --entrypoint sh ghcr.io/abhigyanpatwari/gitnexus:latest -c `
            "node /app/gitnexus/dist/cli/index.js analyze /repo --skip-git --force" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $gitnexusOk = $true
            Write-Host "[PASS] gitnexus index built (via Docker)" -ForegroundColor Green
        } else {
            Write-Host "[WARN] gitnexus Docker analyze failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] Docker Desktop not detected — gitnexus requires Docker on Windows." -ForegroundColor Yellow
        Write-Host "       Install from: https://docs.docker.com/desktop/setup/install/windows-install/" -ForegroundColor Gray
        Write-Host "       After install, re-run setup (gitnexus is NON-FATAL)." -ForegroundColor Gray
    }
}

# ---- Step 4: Create .claude directory ----
Write-Host ""
Write-Host "--- .claude/ structure ---" -ForegroundColor Yellow
$claudeDir = ".claude"
if (-not (Test-Path $claudeDir)) {
    $null = New-Item -ItemType Directory -Path $claudeDir -Force
}
$hooksDir = ".claude/hooks"
if (-not (Test-Path $hooksDir)) {
    $null = New-Item -ItemType Directory -Path $hooksDir -Force
}
Write-Host "[PASS] .claude/ + hooks/ created" -ForegroundColor Green

# ---- Step 5: settings.json ----
Write-Host ""
Write-Host "--- settings.json ---" -ForegroundColor Yellow
$settingsPath = ".claude/settings.json"
$existingSettings = $null
if (Test-Path $settingsPath) {
    if ($mergeMode) {
        try {
            $existingSettings = Get-Content $settingsPath -Raw -Encoding utf8 | ConvertFrom-Json
            Write-Host "[SKIP] settings.json exists (merge mode — patching if needed)" -ForegroundColor Yellow
        } catch {
            Write-Host "[WARN] settings.json exists but is invalid JSON — will overwrite" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[FRESH] overwriting settings.json" -ForegroundColor Yellow
    }
}

# Build new settings scaffold
$settings = @{
    permissions = @{
        allow = @(
            "Bash(*)",
            "PowerShell(*)",
            "Read",
            "Edit",
            "Write",
            "Glob",
            "Grep",
            "Bash(devflow *)",
            "Bash(python -m devflow *)",
            "PowerShell(devflow *)"
        )
    }
    hooks = @{
        PreToolUse = @(
            @{
                matcher = "Bash"
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -NoProfile -File .claude/hooks/guardrails-git.ps1"
                        shell = "powershell"
                        timeout = 5
                        statusMessage = "devflow: checking git safety..."
                    }
                )
            }
        )
        SessionStart = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -NoProfile -File .claude/hooks/session-start.ps1"
                    }
                )
            }
        )
    }
}

if ($existingSettings -and $mergeMode) {
    # Merge: keep existing permissions, add devflow hooks if missing
    $existingSettings | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding utf8
    Write-Host "[SKIP] settings.json unchanged (use --fresh to overwrite)" -ForegroundColor Yellow
} else {
    $settings | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding utf8
    Write-Host "[PASS] settings.json created" -ForegroundColor Green
}

# ---- Step 6: Guardrails hooks ----
Write-Host ""
Write-Host "--- guardrails hooks ---" -ForegroundColor Yellow

# guardrails-git.ps1
$guardrailsPs1 = ".claude/hooks/guardrails-git.ps1"
if (-not (Test-Path $guardrailsPs1) -or -not $mergeMode) {
@"
# guardrails-git.ps1
# PreToolUse hook for Bash — blocks dangerous git commands.
`$inputJson = [Console]::In.ReadToEnd()
if (-not `$inputJson) { return }
try { `$payload = `$inputJson | ConvertFrom-Json } catch { return }
`$command = `$payload.tool_input.command
if (-not `$command) { return }

`$dangerous = @(
    'git push --force', 'git push -f', 'git push origin +',
    'git reset --hard', 'git checkout .', 'git checkout --',
    'git restore .', 'git restore --staged .',
    'git clean -f', 'git clean -fd',
    'git branch -D', 'git rebase -i HEAD',
    'git --no-verify', 'git commit --no-verify'
)
foreach (`$pattern in `$dangerous) {
    if (`$command -match [regex]::Escape(`$pattern)) {
        @{ action = "reject"; message = "devflow guardrails: blocked dangerous git command: `$pattern" } | ConvertTo-Json -Compress
        return
    }
}
"@ | Out-File $guardrailsPs1 -Encoding utf8
    Write-Host "[PASS] guardrails-git.ps1 installed" -ForegroundColor Green
} else {
    Write-Host "[SKIP] guardrails-git.ps1 already exists" -ForegroundColor Yellow
}

# guardrails-git.sh
$guardrailsSh = ".claude/hooks/guardrails-git.sh"
if (-not (Test-Path $guardrailsSh) -or -not $mergeMode) {
@'
#!/bin/bash
# guardrails-git.sh — PreToolUse hook for Bash
input=$(cat)
command=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input']['command'])" 2>/dev/null)
[ -z "$command" ] && exit 0
dangerous=(
  'git push --force' 'git push -f' 'git push origin +'
  'git reset --hard' 'git checkout .' 'git checkout --'
  'git restore .' 'git restore --staged .'
  'git clean -f' 'git clean -fd'
  'git branch -D' 'git rebase -i HEAD'
  'git --no-verify' 'git commit --no-verify'
)
for pattern in "${dangerous[@]}"; do
  if [[ "$command" == *"$pattern"* ]]; then
    echo "{\"action\":\"reject\",\"message\":\"devflow guardrails: blocked dangerous git command: $pattern\"}"
    exit 0
  fi
done
'@ | Out-File $guardrailsSh -Encoding utf8
    Write-Host "[PASS] guardrails-git.sh installed" -ForegroundColor Green
} else {
    Write-Host "[SKIP] guardrails-git.sh already exists" -ForegroundColor Yellow
}

# ---- Step 7: Session hook ----
Write-Host ""
Write-Host "--- session hooks ---" -ForegroundColor Yellow

$sessionStart = ".claude/hooks/session-start.ps1"
if (-not (Test-Path $sessionStart) -or -not $mergeMode) {
@"
# session-start.ps1 — devflow session start hook
Write-Host "devflow: session start" -ForegroundColor Cyan
`$stateFile = ".devflow/state"
if (Test-Path `$stateFile) {
    try {
        `$state = Get-Content `$stateFile -Raw -Encoding utf8 | ConvertFrom-Json
        Write-Host "devflow: Phase `$(`$state.phase) | step: `$(`$state.step) | feature: `$(`$state.feature)" -ForegroundColor Cyan
    } catch { }
}
"@ | Out-File $sessionStart -Encoding utf8
    Write-Host "[PASS] session-start.ps1 installed" -ForegroundColor Green
} else {
    Write-Host "[SKIP] session-start.ps1 already exists" -ForegroundColor Yellow
}

# ---- Step 8: Seed docs/ ----
Write-Host ""
Write-Host "--- seed docs/ ---" -ForegroundColor Yellow

# Create doc directories
$docDirs = @(
    "docs/prd",
    "docs/ux",
    "docs/adr",
    "docs/tdd",
    "docs/superpowers/specs"
)
foreach ($d in $docDirs) {
    if (-not (Test-Path $d)) {
        $null = New-Item -ItemType Directory -Path $d -Force
    }
}

# CONTEXT.md
$contextMd = "docs/CONTEXT.md"
if (-not (Test-Path $contextMd) -or -not $mergeMode) {
@"
# Project Context

## Project
<!-- TODO: describe what this project does -->

## Domain Glossary
<!-- TODO: add key terms and definitions -->
"@ | Out-File $contextMd -Encoding utf8
    Write-Host "[PASS] docs/CONTEXT.md seeded" -ForegroundColor Green
} else {
    Write-Host "[SKIP] docs/CONTEXT.md already exists" -ForegroundColor Yellow
}

# ADR index
$adrIndex = "docs/adr/README.md"
if (-not (Test-Path $adrIndex) -or -not $mergeMode) {
@"
# Architecture Decision Records

## ADR Index

<!-- Add new ADRs below -->
"@ | Out-File $adrIndex -Encoding utf8
    Write-Host "[PASS] docs/adr/ seeded" -ForegroundColor Green
} else {
    Write-Host "[SKIP] docs/adr/ already exists" -ForegroundColor Yellow
}

# TDD philosophy
$tddFile = "docs/tdd/testing-philosophy.md"
if (-not (Test-Path $tddFile) -or -not $mergeMode) {
@"
# Testing Philosophy

## Principles

1. **Test behavior, not implementation** — tests should verify outcomes, not internals
2. **Write tests before code** — TDD cycle: Red → Green → Refactor
3. **One assertion per test** — each test verifies one behavior
4. **Tests are documentation** — a good test suite describes how the system works
"@ | Out-File $tddFile -Encoding utf8
    Write-Host "[PASS] docs/tdd/ seeded" -ForegroundColor Green
} else {
    Write-Host "[SKIP] docs/tdd/ already exists" -ForegroundColor Yellow
}

# ---- Step 9: .gitignore ----
Write-Host ""
Write-Host "--- .gitignore ---" -ForegroundColor Yellow
$gitignore = ".gitignore"
if (-not (Test-Path $gitignore) -or -not $mergeMode) {
@"
# devflow
.devflow/
.beads/
.gitnexus/

# OS
.DS_Store
Thumbs.db

# Python
__pycache__/
*.pyc
*.pyo
.env
.venv/
venv/
"@ | Out-File $gitignore -Encoding utf8
    Write-Host "[PASS] .gitignore created" -ForegroundColor Green
} else {
    # Append devflow entries if missing
    $content = Get-Content $gitignore -Raw -Encoding utf8
    $devflowEntries = @(".devflow/", ".beads/", ".gitnexus/")
    $added = $false
    foreach ($entry in $devflowEntries) {
        if ($content -notmatch [regex]::Escape($entry)) {
            $content += "`n$entry"
            $added = $true
        }
    }
    if ($added) {
        $content | Out-File $gitignore -Encoding utf8
        Write-Host "[PASS] devflow entries added to .gitignore" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] .gitignore already has devflow entries" -ForegroundColor Yellow
    }
}

# ---- Step 10: Autoresearch ----
if (-not $SkipAutoresearch) {
    Write-Host ""
    Write-Host "--- autoresearch ---" -ForegroundColor Yellow
    try {
        $npxCmd = if ($IsWindows -or $env:OS) { "npx.cmd" } else { "npx" }
        & $npxCmd --yes skills add uditgoenka/autoresearch --yes --claude 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[PASS] autoresearch installed" -ForegroundColor Green
        } else {
            Write-Host "[WARN] autoresearch install had issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARN] autoresearch install failed: $_" -ForegroundColor Yellow
    }
}

# ---- Summary ----
Write-Host ""
Write-Host "=== devflow scaffold ready ===" -ForegroundColor Cyan
Write-Host "  .devflow/     state tracking" -ForegroundColor Gray
Write-Host "  .beads/       issue tracking" -ForegroundColor Gray
Write-Host "  .gitnexus/    code graph (if Docker available)" -ForegroundColor Gray
Write-Host "  .claude/      hooks + settings" -ForegroundColor Gray
Write-Host "  docs/         seed docs" -ForegroundColor Gray
Write-Host "  .gitignore    devflow entries" -ForegroundColor Gray
Write-Host ""
Write-Host "Open in Claude Code — devflow guides the pipeline." -ForegroundColor Green
