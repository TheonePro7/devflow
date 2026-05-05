<#
.SYNOPSIS
    Merge devflow settings into existing .claude/settings.json with dedup.
.DESCRIPTION
    Reads existing settings, merges devflow hooks (dedup by event+matcher+command+type+shell),
    preserves existing permissions/env/directories, handles parse errors with backup.
    Compatible with Windows PowerShell 5.1 and PowerShell 7+.
.PARAMETER TargetPath
    Path to the target .claude/settings.json. Default: .claude/settings.json
.PARAMETER DryRun
    If set, show what would be merged but don't write.
.PARAMETER NoBackup
    If set, skip creating .bak before modifying.
.EXAMPLE
    .\scripts\merge-settings.ps1
    .\scripts\merge-settings.ps1 -DryRun
#>

param(
    [string]$TargetPath = ".claude/settings.json",
    [switch]$DryRun,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"

function ConvertPSObjectToHashtable {
    <#
    .SYNOPSIS
        Recursively converts a PSObject to a hashtable.
        Handles nested objects, arrays, and primitive values.
        Compatible with PowerShell 5.1 (no -AsHashtable).
    #>
    param($InputObject)

    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $hash = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $hash[$prop.Name] = ConvertPSObjectToHashtable -InputObject $prop.Value
        }
        return $hash
    }

    if ($InputObject -is [System.Collections.IList]) {
        $result = @()
        foreach ($item in $InputObject) {
            $result += ConvertPSObjectToHashtable -InputObject $item
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $hash = @{}
        foreach ($key in $InputObject.Keys) {
            $hash[$key] = ConvertPSObjectToHashtable -InputObject $InputObject[$key]
        }
        return $hash
    }

    return $InputObject
}

function Get-DevflowDefaults {
    <#
    .SYNOPSIS
        Returns the baseline settings hashtable that devflow needs.
    #>
    $homeDir = $env:USERPROFILE
    if (-not $homeDir) { $homeDir = $env:HOME }
    if (-not $homeDir) { $homeDir = "~" }

    $superpowersDirs = @(
        "$homeDir\.claude\skills\superpowers-brainstorming",
        "$homeDir\.claude\skills\superpowers-writing-plans",
        "$homeDir\.claude\skills\superpowers-using-git-worktrees",
        "$homeDir\.claude\skills\superpowers-subagent-driven-development",
        "$homeDir\.claude\skills\superpowers-requesting-code-review",
        "$homeDir\.claude\skills\superpowers-finishing-a-development-branch",
        "$homeDir\.claude\skills\superpowers-test-driven-development"
    )

    return @{
        hooks = @{
            PreCompact = @(
                @{
                    matcher = ""
                    hooks = @(
                        @{ type = "command"; command = "bd prime" }
                    )
                }
            )
            PreToolUse = @(
                @{
                    matcher = "Bash"
                    hooks = @(
                        @{
                            type = "command"
                            shell = "powershell"
                            command = "powershell -NoProfile -File .claude/hooks/guardrails-git.ps1"
                            timeout = 5
                            statusMessage = "devflow: checking git safety..."
                        }
                    )
                }
                @{
                    matcher = "Bash"
                    hooks = @(
                        @{
                            type = "command"
                            shell = "bash"
                            command = "bash .claude/hooks/guardrails-git.sh"
                            timeout = 5
                            statusMessage = "devflow: checking git safety..."
                        }
                    )
                }
            )
            SessionStart = @(
                @{
                    hooks = @(
                        @{
                            type = "command"
                            shell = "powershell"
                            command = "powershell -File .claude/hooks/devflow-init-check.ps1"
                            timeout = 10
                            statusMessage = "devflow: checking project state..."
                        }
                    )
                }
                @{
                    hooks = @(
                        @{
                            type = "command"
                            shell = "bash"
                            command = "bash .claude/hooks/devflow-init-check.sh"
                            timeout = 10
                            statusMessage = "devflow: checking project state..."
                        }
                    )
                }
                @{
                    matcher = ""
                    hooks = @(
                        @{ type = "command"; command = "bd prime" }
                    )
                }
            )
        }
        permissions = @{
            additionalDirectories = $superpowersDirs
        }
    }
}

function Get-HookKey {
    <#
    .SYNOPSIS
        Unique dedup key for a hook entry: "matcher|command|type|shell".
        Normalizes the hooks property to always read the first element.
    #>
    param([hashtable]$Entry)

    $m = if ($Entry.ContainsKey("matcher") -and $Entry.matcher) { $Entry.matcher } else { "" }
    $c = ""
    $t = "command"
    $s = ""

    # Normalize: hooks could be a single object or an array, make it array
    $hooksArray = @()
    if ($Entry.ContainsKey("hooks")) {
        $hooksVal = $Entry.hooks
        if ($hooksVal -is [array]) {
            $hooksArray = $hooksVal
        } elseif ($null -ne $hooksVal) {
            $hooksArray = @($hooksVal)
        }
    }

    if ($hooksArray.Count -gt 0 -and $null -ne $hooksArray[0]) {
        $first = $hooksArray[0]
        if ($first -is [hashtable]) {
            $c = if ($first.ContainsKey("command") -and $first.command) { $first.command } else { "" }
            $t = if ($first.ContainsKey("type") -and $first.type) { $first.type } else { "command" }
            $s = if ($first.ContainsKey("shell") -and $first.shell) { $first.shell } else { "" }
        }
    }

    return "$m|$c|$t|$s"
}

function Normalize-HookEntry {
    <#
    .SYNOPSIS
        Ensures a hook entry always has hooks as an array (not a single object).
    #>
    param([hashtable]$Entry)

    if ($Entry.ContainsKey("hooks")) {
        $hooksVal = $Entry.hooks
        if ($null -ne $hooksVal -and -not ($hooksVal -is [array])) {
            $Entry.hooks = @($hooksVal)
        }
    }
    return $Entry
}

function Merge-HooksByEvent {
    <#
    .SYNOPSIS
        For a single hook event, merges devflow entries into existing entries,
        deduplicating by hook key. Normalizes hook structures.
    #>
    param(
        [array]$ExistingEntries,
        [array]$DevflowEntries
    )

    # Normalize all entries first
    $normalizedExisting = @()
    foreach ($entry in $ExistingEntries) {
        if ($entry -is [hashtable]) {
            $normalizedExisting += Normalize-HookEntry -Entry $entry
        }
    }

    $normalizedDevflow = @()
    foreach ($entry in $DevflowEntries) {
        if ($entry -is [hashtable]) {
            $normalizedDevflow += Normalize-HookEntry -Entry $entry
        }
    }

    $result = @() + $normalizedExisting
    $existingKeys = @{}

    foreach ($entry in $normalizedExisting) {
        $key = Get-HookKey -Entry $entry
        $existingKeys[$key] = $true
    }

    foreach ($entry in $normalizedDevflow) {
        $key = Get-HookKey -Entry $entry
        if (-not $existingKeys.ContainsKey($key)) {
            $result += $entry
            $existingKeys[$key] = $true
        }
    }

    return $result
}

function Merge-Settings {
    <#
    .SYNOPSIS
        Main merge orchestrator.
    #>
    param(
        [string]$Path,
        [bool]$CreateBackup,
        [bool]$DryRun
    )

    $devflowDefaults = Get-DevflowDefaults
    $existing = $null
    $hadParseError = $false

    # Step 1: Read existing settings (if any)
    if (Test-Path $Path) {
        try {
            $content = Get-Content $Path -Raw -ErrorAction Stop
            if (-not [string]::IsNullOrWhiteSpace($content)) {
                $existingObj = $content | ConvertFrom-Json -ErrorAction Stop
                $existing = ConvertPSObjectToHashtable -InputObject $existingObj
            }
        } catch {
            $hadParseError = $true
            Write-Warning "settings.json has syntax errors — backing up and starting fresh."
            if ($CreateBackup -and -not $DryRun) {
                $bakPath = "$Path.bak"
                try {
                    Copy-Item $Path $bakPath -Force -ErrorAction Stop
                    Write-Host "[BAK] Saved backup to $bakPath"
                } catch {
                    Write-Warning "Failed to create backup: $_"
                }
            }
            $existing = $null
        }
    }

    # Step 2: Start with devflow defaults, overlay existing settings
    $merged = $devflowDefaults

    if ($existing -and -not $hadParseError) {
        if ($existing.ContainsKey("hooks") -and $existing.hooks -is [hashtable]) {
            foreach ($hookEvent in $existing.hooks.Keys) {
                $existingEntries = $existing.hooks[$hookEvent]
                $devflowEntries = if ($merged.hooks.ContainsKey($hookEvent)) { $merged.hooks[$hookEvent] } else { @() }

                if ($existingEntries -is [array] -and $existingEntries.Count -gt 0) {
                    $merged.hooks[$hookEvent] = Merge-HooksByEvent -ExistingEntries $existingEntries -DevflowEntries $devflowEntries
                }
            }
        }

        # Merge permissions
        if ($existing.ContainsKey("permissions") -and $existing.permissions -is [hashtable]) {
            $exDirs = if ($existing.permissions.ContainsKey("additionalDirectories") -and $existing.permissions.additionalDirectories -is [array]) {
                @($existing.permissions.additionalDirectories | Where-Object { $_ })
            } else { @() }
            $dfDirs = if ($merged.permissions.ContainsKey("additionalDirectories") -and $merged.permissions.additionalDirectories -is [array]) {
                @($merged.permissions.additionalDirectories)
            } else { @() }

            $exDirsNormalized = $exDirs | ForEach-Object { $_ -replace '\\', '/' }
            $allDirs = @() + $exDirs
            foreach ($dir in $dfDirs) {
                $dirNorm = $dir -replace '\\', '/'
                $found = $false
                foreach ($ed in $exDirsNormalized) {
                    if ($dirNorm -eq $ed) { $found = $true; break }
                }
                if (-not $found) {
                    $allDirs += $dir
                }
            }
            $merged.permissions.additionalDirectories = $allDirs

            foreach ($field in @("allow", "deny", "ask", "defaultMode")) {
                if ($existing.permissions.ContainsKey($field)) {
                    $merged.permissions[$field] = $existing.permissions[$field]
                }
            }
        }

        if ($existing.ContainsKey("env") -and $existing.env -is [hashtable]) {
            $merged.env = $existing.env
        }

        foreach ($field in @("`$schema", "language", "model", "attribution", "respectGitignore", "cleanupPeriodDays", "enabledPlugins")) {
            if ($existing.ContainsKey($field) -and $null -ne $existing[$field]) {
                $merged[$field] = $existing[$field]
            }
        }
    }

    # Step 3: Write result
    if ($DryRun) {
        Write-Host "=== DRY RUN — Would write to $Path ===" -ForegroundColor Cyan
        $mergedJson = $merged | ConvertTo-Json -Depth 10
        Write-Host $mergedJson
        return
    }

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null
    }

    $mergedJson = $merged | ConvertTo-Json -Depth 10
    $mergedJson | Out-File $Path -Encoding utf8 -ErrorAction Stop
    Write-Host "[OK] Merged settings written to $Path" -ForegroundColor Green

    if ($hadParseError) {
        Write-Host "[INFO] Previous settings (with errors) backed up to $Path.bak" -ForegroundColor Yellow
    }
}

# --- Main ---
Merge-Settings -Path $TargetPath -CreateBackup (-not $NoBackup.IsPresent) -DryRun $DryRun.IsPresent
