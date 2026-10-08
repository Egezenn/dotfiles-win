<#
.SYNOPSIS
    Configures persistent Windows User environment variables and PATH order.

.DESCRIPTION
    Sets the following variables at the User scope:
      - MSYSTEM         = "UCRT64"                  (Default MSYS2 subsystem)
      - CHERE_INVOKING  = "1"                       (Preserve current working directory)
      - MSYS2_PATH_TYPE = "inherit"                 (Inherit Windows %PATH%)
      - MSYS            = "winsymlinks:nativestrict" (Native NTFS symlinks)
      - EDITOR          = "nano"                    (Default terminal editor)
      - VISUAL          = "codium"                    (Default visual editor)
      - XDG_CONFIG_HOME = "$env:USERPROFILE\.config" (Standard config directory)
      - STARSHIP_CONFIG = "$env:USERPROFILE\.config\loose\starship.toml" (Global Starship config)
      - Path            = Priority directories at top (deduplicated)
#>
[CmdletBinding()]
param()

$envVars = [ordered]@{
    "MSYSTEM"         = "UCRT64"
    "CHERE_INVOKING"  = "1"
    "MSYS2_PATH_TYPE" = "inherit"
    "MSYS"            = "winsymlinks:nativestrict"
    "EDITOR"          = "nano"
    "VISUAL"          = "codium"
    "XDG_CONFIG_HOME" = "$env:USERPROFILE\.config"
    "STARSHIP_CONFIG" = "$env:USERPROFILE\.config\loose\starship.toml"
}

Write-Host "`n[*] Configuring MSYS2 & User Environment Variables..." -ForegroundColor Cyan

foreach ($entry in $envVars.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "User")
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
    Write-Host "  [+] $($entry.Key.PadRight(18)) = $($entry.Value)" -ForegroundColor Green
}

$priorityPaths = @(
    "$env:USERPROFILE\.local\bin",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
    "$env:ProgramFiles\coreutils\bin",
    "C:\msys64\usr\bin",
    "C:\msys64\ucrt64\bin",
    "$env:USERPROFILE\bin",
    "$env:APPDATA\npm"
)

Write-Host "`n[*] Configuring User PATH precedence..." -ForegroundColor Cyan
$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$existingEntries = if ($currentUserPath) { $currentUserPath -split ';' | Where-Object { $_ -match '\S' } } else { @() }

$finalList = [System.Collections.Generic.List[string]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($dir in $priorityPaths) {
    $trimmed = $dir.TrimEnd('\')
    if ($seen.Add($trimmed)) {
        $finalList.Add($trimmed)
    }
}

foreach ($entry in $existingEntries) {
    $trimmed = $entry.TrimEnd('\')
    if ($seen.Add($trimmed)) {
        $finalList.Add($trimmed)
    }
}

$newUserPath = $finalList -join ';'
[Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")

Write-Host "`n  Top User PATH entries:" -ForegroundColor Yellow
$finalList | Select-Object -First 10 | ForEach-Object -Begin { $i = 1 } -Process {
    Write-Host ("    {0,2}: {1}" -f $i++, $_) -ForegroundColor White
}

Write-Host "`n[OK] Environment variables and User PATH configured successfully.`n" -ForegroundColor Green
