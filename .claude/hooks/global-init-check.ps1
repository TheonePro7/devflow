# global-devflow-init-check.ps1
# Global SessionStart hook — runs in every project.
# If .devflow/state is missing, tells the agent devflow is available but uninitialized.

$ErrorActionPreference = "Stop"

$projectRoot = if (Get-Command git -ErrorAction SilentlyContinue) {
    $root = git rev-parse --show-toplevel 2>$null
    if ($root) { $root } else { (Get-Location).Path }
} else {
    (Get-Location).Path
}

$stateFile = Join-Path $projectRoot ".devflow" "state"
$skillSetup = Join-Path $env:USERPROFILE ".claude" "skills" "devflow" "setup.sh"

if (-not (Test-Path $stateFile) -and (Test-Path $skillSetup)) {
    $output = @{
        systemMessage = "⚙️ devflow 检测到新项目。输入「用 devflow 开发」自动初始化并启动 5 阶段流程。（或手动运行: bash ~/.claude/skills/devflow/setup.sh）"
        hookSpecificOutput = @{
            hookEventName = "SessionStart"
            additionalContext = "devflow skill 已安装但本项目尚未初始化(.devflow/state 不存在)。如需使用 devflow 流程，先运行 setup.sh 初始化。"
        }
    }
    Write-Output ($output | ConvertTo-Json -Compress)
}

exit 0
