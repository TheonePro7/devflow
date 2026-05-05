# devflow-phase-check.ps1
# PreToolUse hook for Edit|Write — checks devflow phase before code changes.

$projectRoot = & git rev-parse --show-toplevel 2>$null
if (-not $projectRoot) { $projectRoot = "." }

$stateFile = Join-Path $projectRoot ".devflow" "state"

if (-not (Test-Path $stateFile)) {
    @{
        systemMessage = "⚙️ devflow: .devflow/state 不存在，请先运行 setup 完成初始化。"
        continue = $true
    } | ConvertTo-Json -Compress
    exit 0
}

try {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    $phase = [int]$state.phase
    $step = $state.step
    $feature = $state.feature
} catch {
    @{
        systemMessage = "⚙️ devflow: state 文件解析失败。"
        continue = $true
    } | ConvertTo-Json -Compress
    exit 0
}

# Read stdin JSON to get the file being edited
try {
    $inputJson = @($input) -join "`n"
    if (-not [string]::IsNullOrEmpty($inputJson)) {
        $hookInput = $inputJson | ConvertFrom-Json
        $filePath = $hookInput.tool_input.file_path
    }
} catch {
    $filePath = ""
}

# Phase 0 or 0.5 — check if editing code files
if ($phase -lt 1 -and -not [string]::IsNullOrEmpty($filePath)) {
    if ($filePath -match '\.(js|ts|py|go|rs|rb|php|c|cpp|h|hpp|java|kt|swift)$') {
        @{
            systemMessage = "⚠️ devflow 流程提醒: 当前 Phase $phase（$step），尚未完成需求梳理。正在尝试修改代码文件。建议先完成 Phase 0 流程。如需继续请确认。"
            continue = $true
        } | ConvertTo-Json -Compress
        exit 0
    }
}

# Phase 2 brainstorming — check if jumping to code
if ($phase -eq 2 -and $step -eq "brainstorming" -and -not [string]::IsNullOrEmpty($filePath)) {
    if ($filePath -match '\.(js|ts|py|go)$') {
        @{
            systemMessage = "⚠️ devflow 流程提醒: 当前在 brainstorming 阶段，直接写代码会跳过 grill → plans → scenario 等步骤。请完成当前阶段后再开始实现。"
            continue = $true
        } | ConvertTo-Json -Compress
        exit 0
    }
}

# All good
@{ continue = $true } | ConvertTo-Json -Compress
