function refreshenv {
    foreach ($level in "Machine", "User") {
        [System.Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            Set-Item -Path "Env:$($_.Key)" -Value $_.Value
        }
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "Environment variables refreshed." -ForegroundColor Green
}
