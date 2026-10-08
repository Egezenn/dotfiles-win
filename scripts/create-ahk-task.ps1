<#
.SYNOPSIS
    Registers the StartAHK scheduled task to launch start.ahk on user logon with elevated privileges.

.DESCRIPTION
    Creates or updates the "StartAHK" scheduled task in Windows Task Scheduler:
      - Trigger: At logon (Interactive)
      - RunLevel: HighestAvailable (elevated)
      - Battery constraints disabled (runs on battery)
      - No execution time limit (runs indefinitely)
      - MultipleInstances: IgnoreNew
      - Working directory: ahk/
#>
[CmdletBinding()]
param(
    [string]$TaskName = "StartAHK",
    [string]$AhkScriptPath,
    [string]$AhkExePath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64_UIA.exe"
)

# Resolve repo root and ahk script path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

if (-not $AhkScriptPath) {
    $AhkScriptPath = Join-Path $RepoRoot "ahk\start.ahk"
}

$WorkingDir = Split-Path -Parent $AhkScriptPath

Write-Host "[INFO] Registering Scheduled Task: $TaskName" -ForegroundColor Cyan
Write-Host "       Executable: $AhkExePath"
Write-Host "       Script:     $AhkScriptPath"
Write-Host "       WorkDir:    $WorkingDir"

$action = New-ScheduledTaskAction `
    -Execute $AhkExePath `
    -Argument "`"$AhkScriptPath`"" `
    -WorkingDirectory $WorkingDir

$trigger = New-ScheduledTaskTrigger -AtLogOn

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan) `
    -MultipleInstances IgnoreNew `
    -Priority 7

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Force | Out-Null

Write-Host "[OK] Task '$TaskName' registered successfully." -ForegroundColor Green