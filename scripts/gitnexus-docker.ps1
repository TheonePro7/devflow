<#
.SYNOPSIS
    Run gitnexus commands via Docker (bypasses Windows tree-sitter SIGSEGV).
.DESCRIPTION
    Wraps ghcr.io/abhigyanpatwari/gitnexus:latest so gitnexus analyze/context/impact
    run inside a Linux container where tree-sitter native modules work correctly.
    Uses --user root and --skip-git to handle Docker on Windows limitations:
    hidden files (.git) not mounted by default, non-root can't write to Windows volumes.
.USAGE
    .\scripts\gitnexus-docker.ps1 analyze [--force]
    .\scripts\gitnexus-docker.ps1 context <symbol> [--repo <name>]
    .\scripts\gitnexus-docker.ps1 impact <symbol> [--depth 2]
    .\scripts\gitnexus-docker.ps1 query "<search>"
    .\scripts\gitnexus-docker.ps1 status
#>

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"
$Image = "ghcr.io/abhigyanpatwari/gitnexus:latest"
$Repo = (Get-Location).Path
$Cli = "node /app/gitnexus/dist/cli/index.js"
$DockerBase = "docker run --rm -v ""${Repo}:/repo"" --user root --entrypoint sh $Image -c"

# Check Docker is available
try {
    $null = docker ps 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Docker not running" }
} catch {
    Write-Host "[FAIL] Docker is not available. Install Docker Desktop or fall back to native gitnexus." -ForegroundColor Red
    exit 1
}

# Pull image if not present (non-blocking)
$null = docker image inspect $Image 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[INFO] Pulling gitnexus Docker image (first run only)..." -ForegroundColor Yellow
    docker pull $Image 2>&1 | Out-Null
}

switch ($Command.ToLower()) {
    "analyze" {
        $force = if ($Arguments -contains "--force") { "--force" } else { "" }
        Invoke-Expression "$DockerBase -c ""$Cli analyze /repo --skip-git $force 2>&1"""
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[PASS] gitnexus analyze complete" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] gitnexus analyze failed" -ForegroundColor Red
        }
    }
    "context" {
        if ($Arguments.Count -eq 0) { Write-Host "Usage: gitnexus-docker context <symbol> [--repo <name>]" -ForegroundColor Yellow; exit 1 }
        $symbol = $Arguments[0]
        $extraArgs = ""
        if ($Arguments -contains "--repo") {
            $idx = [array]::IndexOf($Arguments, "--repo")
            $extraArgs = "--repo $($Arguments[$idx+1])"
        }
        Invoke-Expression "$DockerBase -c ""$Cli analyze /repo --skip-git --force 2>&1 | tail -1 && $Cli context $extraArgs $symbol --repo /repo 2>&1"""
    }
    "impact" {
        if ($Arguments.Count -eq 0) { Write-Host "Usage: gitnexus-docker impact <symbol> [--depth 2]" -ForegroundColor Yellow; exit 1 }
        $symbol = $Arguments[0]
        $depth = if ($Arguments -contains "--depth") { $idx = [array]::IndexOf($Arguments, "--depth"); "--depth $($Arguments[$idx+1])" } else { "" }
        Invoke-Expression "$DockerBase -c ""$Cli analyze /repo --skip-git --force 2>&1 | tail -1 && $Cli impact $depth $symbol --repo /repo 2>&1"""
    }
    "query" {
        $query = $Arguments -join " "
        if ([string]::IsNullOrWhiteSpace($query)) { Write-Host "Usage: gitnexus-docker query <search-text>" -ForegroundColor Yellow; exit 1 }
        Invoke-Expression "$DockerBase -c ""$Cli analyze /repo --skip-git --force 2>&1 | tail -1 && $Cli query --repo /repo '$query' 2>&1"""
    }
    "status" {
        if (Test-Path ".gitnexus/meta.json") {
            $meta = Get-Content ".gitnexus/meta.json" | ConvertFrom-Json
            Write-Host "gitnexus index: $($meta.stats.nodes) nodes, $($meta.stats.edges) edges, $($meta.stats.communities) clusters" -ForegroundColor Cyan
            Write-Host "  indexed: $($meta.indexedAt)" -ForegroundColor Gray
        } else {
            Write-Host "no gitnexus index found - run 'gitnexus-docker analyze --force'" -ForegroundColor Yellow
        }
    }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Available: analyze, context, impact, query, status" -ForegroundColor Yellow
    }
}
