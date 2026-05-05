# prd-to-beads.ps1
# Parses a design doc markdown and creates beads issues for each task.
#
# Usage:
#   .\scripts\prd-to-beads.ps1 -DesignDoc .\docs\superpowers\specs\my-design.md -EpicTitle "My Feature"
#
# The script looks for:
#   - ## Task: lines as task titles
#   - Lines starting with - [ ] or - [ ] ** beneath each task for sub-tasks
#   - Depends on: markers for dependency relationships

param(
    [Parameter(Mandatory)]
    [string]$DesignDoc,

    [Parameter(Mandatory)]
    [string]$EpicTitle,

    [string]$EpicId = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $DesignDoc)) {
    Write-Error "Design doc not found: $DesignDoc"
    exit 1
}

if (-not (Get-Command "bd" -ErrorAction SilentlyContinue)) {
    Write-Error "beads (bd) not found — install: go install github.com/gastownhall/beads/cmd/bd@latest"
    exit 1
}

# Step 1: Create epic if no ID provided
if (-not $EpicId) {
    Write-Host "[beads] Creating epic: $EpicTitle" -ForegroundColor Yellow
    $epicOutput = bd create --title="$EpicTitle" --type=epic 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create epic: $epicOutput"
        exit 1
    }
    # Extract ID from output (assumes format like "bd-a1b2")
    $EpicId = ($epicOutput | Select-String -Pattern "bd-[a-z0-9]+").Matches.Value
    if (-not $EpicId) {
        Write-Warning "Could not parse epic ID from output, using raw output"
        $EpicId = $epicOutput.Trim()
    }
    Write-Host "[OK] Epic ID: $EpicId" -ForegroundColor Green
}

# Step 2: Parse tasks from design doc
$content = Get-Content $DesignDoc -Raw
$lines = $content -split "`n"
$tasks = @()

$currentTask = $null
foreach ($line in $lines) {
    $trimmed = $line.Trim()

    # Match "## Task: <title>"
    if ($trimmed -match "^## Task:\s+(.+)$") {
        if ($currentTask) { $tasks += $currentTask }
        $currentTask = @{
            Title = $matches[1].Trim()
            Deps = @()
        }
    }
    # Match "Depends on: <id-or-title>"
    elseif ($currentTask -and $trimmed -match "^Depends on:\s+(.+)$") {
        $currentTask.Deps += $matches[1].Trim()
    }
}

if ($currentTask) { $tasks += $currentTask }

if ($tasks.Count -eq 0) {
    Write-Host "[WARN] No '## Task:' headings found in $DesignDoc" -ForegroundColor Yellow
    Write-Host "       Create issues manually: bd create --title='<task>' --parent=$EpicId --type=task"
    exit 0
}

# Step 3: Create beads issue for each task
$taskIds = @{}
foreach ($task in $tasks) {
    Write-Host "[beads] Creating task: $($task.Title)" -ForegroundColor Yellow
    $output = bd create --title="$($task.Title)" --parent=$EpicId --type=task 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to create task: $output"
        continue
    }
    $taskId = ($output | Select-String -Pattern "bd-[a-z0-9]+\.[0-9]+").Matches.Value
    if (-not $taskId) {
        $taskId = $output.Trim()
    }
    $taskIds[$task.Title] = $taskId
    Write-Host "  -> $taskId" -ForegroundColor Green
}

# Step 4: Add dependencies
foreach ($task in $tasks) {
    foreach ($dep in $task.Deps) {
        # Dep could be a title (lookup in taskIds) or an existing ID
        $depId = if ($taskIds.ContainsKey($dep)) { $taskIds[$dep] } else { $dep }
        $taskId = $taskIds[$task.Title]
        Write-Host "[beads] Adding dep: $taskId -> $depId" -ForegroundColor Gray
        bd dep add $taskId $depId 2>&1 | Out-Null
    }
}

Write-Host ""
Write-Host "[DONE] Created $($tasks.Count) tasks under epic $EpicId" -ForegroundColor Cyan
