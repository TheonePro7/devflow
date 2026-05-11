# devflow-state-check.ps1
# UserPromptSubmit hook — injects current devflow state + Phase 4 step guidance.
# Reads .devflow/state and outputs a structured reminder with next-step instructions.

$projectRoot = & git rev-parse --show-toplevel 2>$null
if (-not $projectRoot) { $projectRoot = "." }

$stateFile = Join-Path $projectRoot ".devflow" "state"

if (Test-Path $stateFile) {
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        $phase = $state.phase
        $step = $state.step
        $feature = $state.feature
        $featurePart = if ([string]::IsNullOrEmpty($feature)) { "" } else { "功能: $feature" }

        # Phase 4 step-specific guidance
        $guidance = ""
        $stepActions = @{
            "brainstorming" = "下一步: 调用 /brainstorming 技能进行设计探索"
            "probe"         = "下一步: 调用 /autoresearch:probe 检查隐藏约束"
            "writing-plans" = "下一步: 调用 /writing-plans 生成实施计划"
            "subagent-dev"  = "下一步: 调用 /subagent-driven-development 执行开发"
            "impl"          = "下一步: 调用 /subagent-driven-development 或 /executing-plans 执行"
            "security"      = "下一步: 调用 /autoresearch:security --diff 审计"
            "finish-branch" = "下一步: 调用 /finishing-a-development-branch 完成分支"
        }
        if ($phase -eq 4 -and $stepActions.ContainsKey($step)) {
            $guidance = " | $($stepActions[$step])"
        }

        @{
            systemMessage = "⚙️ devflow: [Phase $phase] [Step: $step] $featurePart$guidance"
        } | ConvertTo-Json -Compress

    } catch {
        @{
            systemMessage = "⚙️ devflow: state 文件解析失败，请检查 .devflow/state 格式。"
        } | ConvertTo-Json -Compress
    }
} else {
    @{
        systemMessage = "⚙️ devflow: .devflow/state 不存在。新项目请运行 setup.sh 或输入 '用devflow 开发' 自动初始化。"
    } | ConvertTo-Json -Compress
}
