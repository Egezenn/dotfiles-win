<#
.SYNOPSIS
    Configures persistent Windows User environment variables for MSYS2 + Zsh.

.DESCRIPTION
    Sets the following variables at the User scope:
      - MSYSTEM         = "UCRT64"                  (Default MSYS2 subsystem)
      - CHERE_INVOKING  = "1"                       (Preserve current working directory)
      - MSYS2_PATH_TYPE = "inherit"                 (Inherit Windows %PATH%)
      - MSYS            = "winsymlinks:nativestrict" (Native NTFS symlinks)
#>
[CmdletBinding()]
param()

$envVars = [ordered]@{
    "MSYSTEM"         = "UCRT64"
    "CHERE_INVOKING"  = "1"
    "MSYS2_PATH_TYPE" = "inherit"
    "MSYS"            = "winsymlinks:nativestrict"
}

Write-Host "`n[*] Configuring MSYS2 User Environment Variables..." -ForegroundColor Cyan

foreach ($entry in $envVars.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "User")
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
    Write-Host "  [+] $($entry.Key.PadRight(18)) = $($entry.Value)" -ForegroundColor Green
}

Write-Host "`n[OK] Environment variables set successfully.`n" -ForegroundColor Green
