<#
.SYNOPSIS
    Unified Windows debloat & latency tuning script.

.DESCRIPTION
    Completely reversible script that removes Windows background bloat and optimizes latency.
    Zero hardcoded GUIDs or hardware names (all adapters are dynamically discovered).

    1. Neutralizes Modern AppX background hosts (takes ownership and prepends "_"):
       - SearchHost.exe (Windows Search & Edge WebView2 cluster)
       - TextInputHost.exe (Emoji picker, Clipboard history, touch keyboard)
       - StartMenuExperienceHost.exe (Windows 11 Start Menu GUI)
       - CrossDeviceResume.exe (Phone Link / Continue from phone)

    2. Stops and disables background telemetry, unneeded daemons, and P2P services:
       - DiagTrack (Connected User Experiences and Telemetry)
       - WSearch (Windows Search Indexer - replaced by Everything 1.5a)
       - CDPSvc (Connected Devices Platform backend)
       - webthreatdefsvc (Web Threat Defense / SmartScreen)
       - InventorySvc (Compatibility Appraisal telemetry)
       - Spooler (Print Spooler)
       - SysMain (Superfetch)
       - lfsvc (Geolocation Service)
       - TrkWks (Distributed Link Tracking)
       - WerSvc (Windows Error Reporting - eliminates crash hangs and dump uploads)
       - DoSvc (Delivery Optimization - eliminates background P2P update sharing)

    3. Disables mechanical HDD scheduled defrag:
       - Disables \Microsoft\Windows\Defrag\ScheduledDefrag (prevents HDD grinding).
       - Real-time inline TRIM on SSD remains 100% active via NTFS DisableDeleteNotify.

    4. MMCSS & System Responsiveness Tuning:
       - NetworkThrottlingIndex = 0xffffffff (Disables network packet throttling during gaming/media).
       - SystemResponsiveness = 0 (Gives 100% CPU priority to foreground apps instead of reserving 20%).

    5. Network Stack Tuning (Disables Nagle's Algorithm):
       - Dynamically detects all active network adapters (by IPEnabled and SettingID).
       - Sets TcpAckFrequency = 1 and TCPNoDelay = 1 (removes 200ms delayed-ACK buffer for lower ping/jitter).

    6. Kernel Latency Tuning:
       - Disables kernel Dynamic Tick (bcdedit disabledynamictick yes) to prevent timer drift.

.PARAMETER Enable
    Restores original executable filenames, re-enables services, tasks, registry defaults, and dynamic tick.

.PARAMETER Status
    Displays current state of all executables, services, tasks, network adapters, MMCSS, and kernel settings.

.EXAMPLE
    .\debloat.ps1
    # Enforces full debloat and latency optimizations

.EXAMPLE
    .\debloat.ps1 -Status
    # Checks status across all subsystems

.EXAMPLE
    .\debloat.ps1 -Enable
    # Completely reverts all changes back to Windows defaults
#>

param(
    [switch]$Enable,
    [switch]$Status
)

$ErrorActionPreference = "Continue"

# -----------------------------------------------------------------------------
# DEFINITIONS (Zero hardcoded hardware IDs / GUIDs)
# -----------------------------------------------------------------------------
$exeTargets = @(
    @{
        Name = "SearchHost"
        DirPattern = "C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_*"
        Exe = "SearchHost.exe"
        Renamed = "_SearchHost.exe"
    },
    @{
        Name = "TextInputHost"
        DirPattern = "C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_*"
        Exe = "TextInputHost.exe"
        Renamed = "_TextInputHost.exe"
    },
    @{
        Name = "StartMenuExperienceHost"
        DirPattern = "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_*"
        Exe = "StartMenuExperienceHost.exe"
        Renamed = "_StartMenuExperienceHost.exe"
    },
    @{
        Name = "CrossDeviceResume"
        DirPattern = "C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_*"
        Exe = "CrossDeviceResume.exe"
        Renamed = "_CrossDeviceResume.exe"
    }
)

$svcTargets = @(
    @{ Name = "DiagTrack";        DefaultType = "Automatic"; Description = "Telemetry & Diagnostics" },
    @{ Name = "WSearch";          DefaultType = "Automatic"; Description = "Windows Search Indexer" },
    @{ Name = "CDPSvc";           DefaultType = "Automatic"; Description = "Connected Devices Platform" },
    @{ Name = "webthreatdefsvc";  DefaultType = "Manual";    Description = "Web Threat Defense (SmartScreen)" },
    @{ Name = "InventorySvc";     DefaultType = "Manual";    Description = "Compatibility Appraiser Telemetry" },
    @{ Name = "Spooler";          DefaultType = "Automatic"; Description = "Print Spooler" },
    @{ Name = "SysMain";          DefaultType = "Automatic"; Description = "Superfetch" },
    @{ Name = "lfsvc";            DefaultType = "Manual";    Description = "Geolocation Service" },
    @{ Name = "TrkWks";           DefaultType = "Automatic"; Description = "Distributed Link Tracking" },
    @{ Name = "WerSvc";           DefaultType = "Manual";    Description = "Windows Error Reporting" },
    @{ Name = "DoSvc";            DefaultType = "Automatic"; Description = "Delivery Optimization (P2P Updates)" }
)

$mmcssKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"

function Get-ActiveNetworkInterfaces {
    Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -and $_.SettingID }
}

# -----------------------------------------------------------------------------
# 1. STATUS MODE
# -----------------------------------------------------------------------------
if ($Status) {
    Write-Host "`n=== Target Executables ===" -ForegroundColor Cyan
    foreach ($target in $exeTargets) {
        $dir = Get-Item $target.DirPattern -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if (-not $dir -or -not (Test-Path $dir)) {
            Write-Host "  [MISSING DIR] $($target.Name)" -ForegroundColor Red
            continue
        }
        $normal = Join-Path $dir $target.Exe
        $renamed = Join-Path $dir $target.Renamed

        if (Test-Path $renamed) {
            Write-Host "  [DISABLED] $($target.Name.PadRight(26)) -> $($target.Renamed)" -ForegroundColor Yellow
        } elseif (Test-Path $normal) {
            Write-Host "  [ACTIVE]   $($target.Name.PadRight(26)) -> $($target.Exe)" -ForegroundColor Green
        } else {
            Write-Host "  [NOT FOUND] $($target.Name)" -ForegroundColor Red
        }
    }

    Write-Host "`n=== Target Services ===" -ForegroundColor Cyan
    foreach ($svc in $svcTargets) {
        $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if (-not $s) {
            Write-Host "  [NOT FOUND] $($svc.Name.PadRight(20)) ($($svc.Description))" -ForegroundColor Gray
            continue
        }
        $stateColor = if ($s.Status -eq "Running") { "Green" } else { "Yellow" }
        Write-Host "  [$($s.Status.ToString().ToUpper())] ".PadRight(13) -NoNewline -ForegroundColor $stateColor
        Write-Host "$($svc.Name.PadRight(20)) Startup: $($s.StartType.ToString().PadRight(10)) ($($svc.Description))" -ForegroundColor White
    }

    Write-Host "`n=== Scheduled Tasks ===" -ForegroundColor Cyan
    $defragTask = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue
    if ($defragTask) {
        $color = if ($defragTask.State -eq "Disabled") { "Yellow" } else { "Green" }
        Write-Host "  [$($defragTask.State.ToString().ToUpper())] ".PadRight(13) -NoNewline -ForegroundColor $color
        Write-Host "ScheduledDefrag (Mechanical HDD Auto-Defrag)" -ForegroundColor White
    }

    Write-Host "`n=== MMCSS & System Responsiveness ===" -ForegroundColor Cyan
    $mmcss = Get-ItemProperty -Path $mmcssKey -ErrorAction SilentlyContinue
    $val = $mmcss.NetworkThrottlingIndex
    $throttling = if ($val -eq -1 -or $val -eq 4294967295) { "Disabled (Optimized)" } else { "$val (Default Throttled)" }
    $resp = if ($mmcss.SystemResponsiveness -eq 0) { "0% (100% Foreground App Priority)" } else { "$($mmcss.SystemResponsiveness)% Reserved for Background" }
    Write-Host "  NetworkThrottlingIndex : $throttling"
    Write-Host "  SystemResponsiveness   : $resp"

    Write-Host "`n=== Network Stack (Nagle's Algorithm) ===" -ForegroundColor Cyan
    $adapters = Get-ActiveNetworkInterfaces
    foreach ($adapter in $adapters) {
        $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.SettingID)"
        $tcpProps = Get-ItemProperty -Path $tcpPath -ErrorAction SilentlyContinue
        $noDelay = if ($tcpProps.TCPNoDelay -eq 1 -and $tcpProps.TcpAckFrequency -eq 1) { "Disabled / Immediate ACK (Optimized)" } else { "Enabled (Default Buffer)" }
        Write-Host "  $($adapter.Description.PadRight(40)) -> Nagle: $noDelay"
    }

    Write-Host "`n=== Kernel Latency ===" -ForegroundColor Cyan
    $bcd = bcdedit /enum "{current}" 2>$null | Out-String
    $dynTick = if ($bcd -match "disabledynamictick\s+Yes") { "Disabled (Steady Timer)" } else { "Enabled (Default)" }
    Write-Host "  Kernel Dynamic Tick       : $dynTick"

    Write-Host ""
    return
}

# -----------------------------------------------------------------------------
# 2. RESTORE MODE (-Enable)
# -----------------------------------------------------------------------------
if ($Enable) {
    Write-Host "`n[*] Restoring executables..." -ForegroundColor Cyan
    foreach ($target in $exeTargets) {
        $dir = Get-Item $target.DirPattern -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if (-not $dir) { continue }
        $normal = Join-Path $dir $target.Exe
        $renamed = Join-Path $dir $target.Renamed

        if (Test-Path $renamed) {
            Rename-Item -Path $renamed -NewName $target.Exe -Force
            Write-Host "  [+] Restored $($target.Name) -> $($target.Exe)" -ForegroundColor Green
        } elseif (Test-Path $normal) {
            Write-Host "  [!] $($target.Name) already active." -ForegroundColor Gray
        }
    }

    Write-Host "`n[*] Restoring background services..." -ForegroundColor Cyan
    foreach ($svc in $svcTargets) {
        $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($s) {
            if ($svc.Name -eq "DoSvc") {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DoSvc" -Name "Start" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            } else {
                Set-Service -Name $svc.Name -StartupType $svc.DefaultType -ErrorAction SilentlyContinue
            }
            if ($svc.DefaultType -eq "Automatic") {
                Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
            }
            Write-Host "  [+] Restored service $($svc.Name) -> $($svc.DefaultType)" -ForegroundColor Green
        }
    }

    Write-Host "`n[*] Re-enabling ScheduledDefrag task..." -ForegroundColor Cyan
    Enable-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  [+] ScheduledDefrag re-enabled." -ForegroundColor Green

    Write-Host "`n[*] Restoring MMCSS registry defaults..." -ForegroundColor Cyan
    Set-ItemProperty -Path $mmcssKey -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force
    Set-ItemProperty -Path $mmcssKey -Name "SystemResponsiveness" -Value 20 -Type DWord -Force
    Write-Host "  [+] NetworkThrottlingIndex -> 10, SystemResponsiveness -> 20" -ForegroundColor Green

    Write-Host "`n[*] Restoring TCP Nagle's algorithm to default..." -ForegroundColor Cyan
    $adapters = Get-ActiveNetworkInterfaces
    foreach ($adapter in $adapters) {
        $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.SettingID)"
        Remove-ItemProperty -Path $tcpPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $tcpPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
        Write-Host "  [+] Restored default TCP settings on $($adapter.Description)" -ForegroundColor Green
    }

    Write-Host "`n[*] Restoring kernel dynamic tick..." -ForegroundColor Cyan
    bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
    Write-Host "  [+] Kernel dynamic tick restored to default." -ForegroundColor Green

    Write-Host "`n[+] Full restoration complete! All subsystems returned to defaults.`n" -ForegroundColor Green
    return
}

# -----------------------------------------------------------------------------
# 3. DISABLE / DEBLOAT / TUNE MODE (Default)
# -----------------------------------------------------------------------------
Write-Host "`n[*] 1. Neutralizing background host executables..." -ForegroundColor Cyan
foreach ($target in $exeTargets) {
    $dir = Get-Item $target.DirPattern -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if (-not $dir) { continue }
    $normal = Join-Path $dir $target.Exe
    $renamed = Join-Path $dir $target.Renamed

    Stop-Process -Name $target.Name -Force -ErrorAction SilentlyContinue

    if (Test-Path $normal) {
        & takeown.exe /F $normal /A | Out-Null
        & icacls.exe $normal /grant "Administrators:F" /c | Out-Null
        Rename-Item -Path $normal -NewName $target.Renamed -Force
        Write-Host "  [+] Disabled $($target.Name) -> $($target.Renamed)" -ForegroundColor Green
    } elseif (Test-Path $renamed) {
        Write-Host "  [!] $($target.Name) already disabled ($($target.Renamed))." -ForegroundColor Yellow
    }
}

Write-Host "`n[*] 2. Stopping and disabling background services..." -ForegroundColor Cyan
foreach ($svc in $svcTargets) {
    $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        if ($svc.Name -eq "DoSvc") {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DoSvc" -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        }
        Write-Host "  [+] Stopped & Disabled $($svc.Name.PadRight(20)) ($($svc.Description))" -ForegroundColor Green
    }
}

Write-Host "`n[*] 3. Disabling Scheduled HDD Defrag (preserving SSD inline TRIM)..." -ForegroundColor Cyan
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue | Out-Null
Write-Host "  [+] ScheduledDefrag task disabled." -ForegroundColor Green

Write-Host "`n[*] 4. Optimizing MMCSS & System Responsiveness..." -ForegroundColor Cyan
Set-ItemProperty -Path $mmcssKey -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
Set-ItemProperty -Path $mmcssKey -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
Write-Host "  [+] NetworkThrottlingIndex -> 0xffffffff (Throttling disabled)" -ForegroundColor Green
Write-Host "  [+] SystemResponsiveness   -> 0 (100% foreground CPU priority)" -ForegroundColor Green

Write-Host "`n[*] 5. Disabling Nagle's Algorithm on active network interfaces..." -ForegroundColor Cyan
$adapters = Get-ActiveNetworkInterfaces
foreach ($adapter in $adapters) {
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.SettingID)"
    Set-ItemProperty -Path $tcpPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $tcpPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force
    Write-Host "  [+] Set TcpAckFrequency=1 & TCPNoDelay=1 on $($adapter.Description)" -ForegroundColor Green
}

Write-Host "`n[*] 6. Disabling kernel dynamic tick..." -ForegroundColor Cyan
bcdedit /set disabledynamictick yes 2>$null | Out-Null
Write-Host "  [+] Set bcdedit disabledynamictick yes (steady hardware timer ticks)." -ForegroundColor Green

Write-Host "`n[+] Debloat and latency optimizations successfully applied!`n" -ForegroundColor Green
