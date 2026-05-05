# devflow-init-check.ps1
# Claude Code SessionStart hook
# Checks if devflow Phase 1 has been initialized in this project.
# Output: structured JSON for Claude context injection.
# Install via: .claude/settings.json -> hooks.SessionStart

$ErrorActionPreference = "Stop"

# Check prerequisites (tool availability)
$bdInstalled = $null -ne (Get-Command "bd" -ErrorAction SilentlyContinue)
$gitnexusInstalled = $null -ne (Get-Command "gitnexus" -ErrorAction SilentlyContinue)

# Check project initialization
$projectRoot = Get-Location
$beadsDir = Join-Path $projectRoot ".beads"
$gitnexusDir = Join-Path $projectRoot ".gitnexus"
$beadsInit = Test-Path $beadsDir
$gitnexusInit = Test-Path $gitnexusDir

# Determine state
$allOk = $bdInstalled -and $gitnexusInstalled -and $beadsInit -and $gitnexusInit

if (-not $allOk) {
    $issues = @()
    if (-not $bdInstalled) { $issues += "beads (bd) not installed" }
    if (-not $gitnexusInstalled) { $issues += "gitnexus not installed" }
    if (-not $beadsInit) { $issues += "beads not initialized (run 'bd init')" }
    if (-not $gitnexusInit) { $issues += "gitnexus index not built (run 'gitnexus analyze .')" }

    $summary = "devflow Phase 1 pending — $($issues -join '; ')"
    $systemMsg = "devflow: Phase 1 setup needed. Run setup.ps1 or setup.sh to initialize beads + gitnexus."

    $output = @{
        systemMessage = $systemMsg
        hookSpecificOutput = @{
            hookEventName = "SessionStart"
            additionalContext = $summary
        }
    }

    Write-Output ($output | ConvertTo-Json -Compress)
}
# else: no output = all good, nothing injected
