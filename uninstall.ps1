<#
.SYNOPSIS
    Uninstall devflow components with tiered safety.
.DESCRIPTION
    Three safety tiers:
    1. Safe (auto): hooks, guardrails, skill, autoresearch
    2. Ask (interactive): docs created by devflow
    3. Warn (--force required): .beads/, .gitnexus/ (data loss risk)
.PARAMETER Hooks
    Remove devflow hooks from settings.json.
.PARAMETER Guardrails
    Remove guardrails hook scripts.
.PARAMETER Skill
    Remove devflow skill from ~/.claude/skills/.
.PARAMETER Autoresearch
    Remove autoresearch skill.
.PARAMETER Docs
    Remove devflow-created docs (prompts for confirmation).
.PARAMETER Beads
    Remove .beads/ directory (requires --Force, data loss warning).
.PARAMETER GitNexus
    Remove .gitnexus/ directory (requires --Force, data loss warning).
.PARAMETER All
    Remove all devflow components with appropriate confirmations.
.PARAMETER Force
    Skip data loss warnings (required for --Beads, --GitNexus).
.EXAMPLE
    .\uninstall.ps1 --hooks --guardrails
    .\uninstall.ps1 --all
    .\uninstall.ps1 --all --Force
#>

param(
    [switch]$Hooks,
    [switch]$Guardrails,
    [switch]$Skill,
    [switch]$Autoresearch,
    [switch]$Docs,
    [switch]$Beads,
    [switch]$GitNexus,
    [switch]$All,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$devflowSkillDir = Join-Path $homeDir ".claude\skills\devflow"
# Note: devflow CLI now installs via pip. This directory may not exist.

# If --all, enable all flags except Beads/GitNexus (those need --force too)
if ($All) {
    $Hooks = $true
    $Guardrails = $true
    $Skill = $true
    $Autoresearch = $true
    $Docs = $true
    if ($Force) { $Beads = $true; $GitNexus = $true }
}

Write-Host "=== devflow uninstall ===" -ForegroundColor Cyan
Write-Host ""

# ---- Tier 1: Safe (auto) ----

# --hooks: Remove devflow hooks from settings.json
if ($Hooks) {
    Write-Host "--- hooks ---" -ForegroundColor Yellow
    $settingsPath = ".claude/settings.json"
    if (Test-Path $settingsPath) {
        $backupPath = "$settingsPath.uninstall-bak"
        Copy-Item $settingsPath $backupPath -Force
        Write-Host "[BAK] Backed up to $backupPath" -ForegroundColor Gray

        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            # Remove devflow-specific hook entries
            $devflowCommands = @(
                "guardrails-git.ps1",
                "guardrails-git.sh",
                "devflow-init-check.ps1",
                "devflow-init-check.sh",
                "bd prime"
            )
            $changed = $false

            if ($settings.hooks) {
                foreach ($event in $settings.hooks.PSObject.Properties.Name) {
                    $entries = @($settings.hooks.$event)
                    $filtered = @()
                    foreach ($entry in $entries) {
                        $keep = $true
                        if ($entry.hooks) {
                            foreach ($hook in $entry.hooks) {
                                foreach ($dc in $devflowCommands) {
                                    if ($hook.command -and $hook.command.Contains($dc)) {
                                        $keep = $false
                                        break
                                    }
                                }
                                if (-not $keep) { break }
                            }
                        }
                        if ($keep) { $filtered += $entry }
                    }
                    if ($filtered.Count -ne $entries.Count) {
                        $settings.hooks.$event = $filtered
                        $changed = $true
                    }
                }
            }

            if ($changed) {
                $settings | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding utf8
                Write-Host "[OK] Devflow hooks removed from settings.json" -ForegroundColor Green
            } else {
                Write-Host "[SKIP] No devflow hooks found" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "[WARN] Could not parse settings.json - restore from backup:" -ForegroundColor Yellow
            Write-Host "       Copy-Item $backupPath $settingsPath -Force" -ForegroundColor Gray
        }
    } else {
        Write-Host "[SKIP] settings.json not found" -ForegroundColor Yellow
    }
}

# --guardrails: Remove guardrails hook scripts
if ($Guardrails) {
    Write-Host ""
    Write-Host "--- guardrails ---" -ForegroundColor Yellow
    $guardrailsFiles = @(
        ".claude/hooks/guardrails-git.ps1",
        ".claude/hooks/guardrails-git.sh"
    )
    foreach ($gf in $guardrailsFiles) {
        if (Test-Path $gf) {
            Remove-Item $gf -Force
            Write-Host "[OK] Removed $gf" -ForegroundColor Green
        } else {
            Write-Host "[SKIP] $gf not found" -ForegroundColor Yellow
        }
    }
}

# --skill: Remove devflow from ~/.claude/skills/
if ($Skill) {
    Write-Host ""
    Write-Host "--- devflow skill ---" -ForegroundColor Yellow
    if (Test-Path $devflowSkillDir) {
        Remove-Item $devflowSkillDir -Recurse -Force
        Write-Host "[OK] Removed $devflowSkillDir" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] devflow skill not found at $devflowSkillDir" -ForegroundColor Yellow
    }
}

# --autoresearch: Remove autoresearch skill
if ($Autoresearch) {
    Write-Host ""
    Write-Host "--- autoresearch ---" -ForegroundColor Yellow
    $arDir = Join-Path $homeDir ".claude\skills\autoresearch"
    if (Test-Path $arDir) {
        Remove-Item $arDir -Recurse -Force
        Write-Host "[OK] Removed autoresearch skill" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] autoresearch not found" -ForegroundColor Yellow
    }
    # Also try skills remove
    $skillsCmd = Get-Command "skills" -ErrorAction SilentlyContinue
    if ($skillsCmd) {
        npx skills remove uditgoenka/autoresearch 2>&1 | Out-Null
        Write-Host "[OK] Removed autoresearch from skills registry" -ForegroundColor Green
    }
}

# ---- Tier 2: Ask (interactive prompt) ----
if ($Docs) {
    Write-Host ""
    Write-Host "--- docs ---" -ForegroundColor Yellow
    $docsDirs = @("docs/tdd", "docs/superpowers")
    foreach ($dd in $docsDirs) {
        if (Test-Path $dd) {
            Write-Host "[WARN] $dd/ was created or modified by devflow." -ForegroundColor Yellow
            Write-Host "       Run the following to remove:" -ForegroundColor Gray
            Write-Host "       Remove-Item '$dd' -Recurse -Force" -ForegroundColor Cyan
        } else {
            Write-Host "[SKIP] $dd/ not found" -ForegroundColor Yellow
        }
    }
}

# ---- Tier 3: Warn (--force required) ----
if ($Beads) {
    Write-Host ""
    Write-Host "--- beads data ---" -ForegroundColor Yellow
    if (Test-Path ".beads") {
        if ($Force) {
            Remove-Item ".beads" -Recurse -Force
            Write-Host "[OK] Removed .beads/" -ForegroundColor Green
        } else {
            Write-Host "[WARN] .beads/ contains issue tracking data." -ForegroundColor Red
            Write-Host "       This will DELETE all issues permanently." -ForegroundColor Red
            Write-Host "       Use --Force to confirm data loss acceptance." -ForegroundColor Cyan
        }
    } else {
        Write-Host "[SKIP] .beads/ not found" -ForegroundColor Yellow
    }
}

if ($GitNexus) {
    Write-Host ""
    Write-Host "--- gitnexus data ---" -ForegroundColor Yellow
    if (Test-Path ".gitnexus") {
        if ($Force) {
            Remove-Item ".gitnexus" -Recurse -Force
            Write-Host "[OK] Removed .gitnexus/" -ForegroundColor Green
        } else {
            Write-Host "[WARN] .gitnexus/ contains code knowledge graph index." -ForegroundColor Red
            Write-Host "       This will DELETE all indexed data permanently." -ForegroundColor Red
            Write-Host "       Use --Force to confirm data loss acceptance." -ForegroundColor Cyan
        }
    } else {
        Write-Host "[SKIP] .gitnexus/ not found" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== uninstall complete ===" -ForegroundColor Cyan
