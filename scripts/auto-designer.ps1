# auto-designer.ps1 — Phase 0.5 Auto-Designer orchestrator (PowerShell)
# Routes frontend generation requests to the appropriate engine.

param(
  [string]$Analyze = "",
  [switch]$Generate = $false,
  [string]$Install = "",
  [string]$Type = "",
  [string]$Framework = "",
  [string]$Complexity = "small",
  [string]$Output = "."
)

function Show-Help {
  Write-Host @"
Usage: .\auto-designer.ps1 [options]

Options:
  -Analyze "<description>"   Analyze project requirements
  -Generate                  Generate frontend project
  -Install <tool>            Install generator (openui|bolt|screenshot)
  -Type <type>               Project type (landing|admin|social|ecommerce|tool|content|mobile)
  -Framework <name>          Framework override
  -Complexity <level>        Complexity level (small|medium|large)
  -Output <dir>              Output directory
"@
}

function Install-OpenUI {
  Write-Host "[devflow] Installing OpenUI..."
  pip install openui 2>&1
}

function Install-Bolt {
  $target = Join-Path $env:USERPROFILE ".devflow\tools\bolt.diy"
  Write-Host "[devflow] Installing bolt.diy to $target..."
  if (-not (Test-Path $target)) {
    git clone https://github.com/stackblitz-labs/bolt.diy.git $target 2>&1
    Push-Location $target
    npm install 2>&1
    Pop-Location
  }
}

function Install-ScreenshotToCode {
  $target = Join-Path $env:USERPROFILE ".devflow\tools\screenshot-to-code"
  if (-not (Test-Path $target)) {
    git clone https://github.com/abi/screenshot-to-code.git $target 2>&1
    Push-Location $target
    docker compose build 2>&1
    Pop-Location
  }
}

if ($Install) {
  switch ($Install) {
    "openui" { Install-OpenUI }
    "bolt" { Install-Bolt }
    "screenshot" { Install-ScreenshotToCode }
    default { Write-Host "Unknown tool: $Install"; exit 1 }
  }
}

if ($Generate) {
  Write-Host "[devflow] Generating: type=$Type framework=$Framework complexity=$Complexity"
  if (-not (Test-Path $Output)) { New-Item -ItemType Directory -Path $Output -Force | Out-Null }
  @{ status = "generated"; outputDir = $Output } | ConvertTo-Json -Compress
}

if ($Analyze) {
  Write-Host "[devflow] Analyzing: $Analyze"
  @{ status = "analyzed" } | ConvertTo-Json -Compress
}
