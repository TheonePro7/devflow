# devflow-state-check.ps1
# UserPromptSubmit hook — injects current devflow state as context.
# Reads .devflow/state and outputs a reminder message.

$projectRoot = & git rev-parse --show-toplevel 2>$null
if (-not $projectRoot) { $projectRoot = "." }

$stateFile = Join-Path $projectRoot ".devflow" "state"

if (Test-Path $stateFile) {
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        $phase = $state.phase
        $step = $state.step
        $feature = $state.feature

        if ([string]::IsNullOrEmpty($feature)) {
            @{
                systemMessage = "⚙️ devflow: 当前没有进行中的功能。如果用户提出新想法，请先读取 .devflow/state 并按 phase 阶段执行，不要直接写代码。"
            } | ConvertTo-Json -Compress
        } elseif ($phase -eq 4) {
            $gateInfo = ""
            if ($null -ne $state.gate_probe) {
                $gateInfo = " | 门禁: probe=$($state.gate_probe) scenario=$($state.gate_scenario) fix=$($state.gate_fix) security=$($state.gate_security)"
            }
            @{
                systemMessage = "⚙️ devflow 状态追踪: [Phase $phase] [Step: $step] 功能: $feature$gateInfo。请按 devflow 流程执行当前步骤，门禁未完成会被 Hook 拦截。"
            } | ConvertTo-Json -Compress
        }
    } catch {
        @{
            systemMessage = "⚙️ devflow: state 文件解析失败，请检查 .devflow/state 格式。"
        } | ConvertTo-Json -Compress
    }
} else {
    @{
        systemMessage = "⚙️ devflow: .devflow/state 不存在。需要先运行 setup 完成初始化。"
    } | ConvertTo-Json -Compress
}
