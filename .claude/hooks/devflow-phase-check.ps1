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
    $phaseRaw = $state.phase  # Keep as original type (int or float)
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

# Phase 1 (Ideate) or Phase 2 (Design) — check if editing code files
if ($phaseRaw -eq 1 -or $phaseRaw -eq 2) {
    if (-not [string]::IsNullOrEmpty($filePath) -and $filePath -match '\.(js|ts|py|go|rs|rb|php|c|cpp|h|hpp|java|kt|swift)$') {
        if ($phaseRaw -eq 1) {
            @{
                systemMessage = "⚠️ devflow 流程提醒: 当前 Phase 1（$step），需求梳理阶段不应直接写代码。请先完成 Phase 1 输出 PRD。"
                continue = $true
            } | ConvertTo-Json -Compress
            exit 0
        }
        # phaseRaw == 2 — frontend code generation is normal for Phase 2 Stage 3
    }
}

# Phase 4 brainstorming — check if jumping to code
if ($phaseRaw -eq 4 -and $step -eq "brainstorming" -and -not [string]::IsNullOrEmpty($filePath)) {
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
