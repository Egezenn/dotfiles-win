#Requires AutoHotkey v2.0

; Display an auto-dismissing tooltip (default 3 seconds)
ShowTooltip(msg, timeoutMs := 3000) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -Abs(timeoutMs))
}

; Extract executable file name from command string or path
ExtractExeName(target) {
    trimmed := Trim(target)
    cmd := ""
    if RegExMatch(trimmed, '^"([^"]+)"', &m)
        cmd := m[1]
    else if RegExMatch(trimmed, '^(\S+)', &m)
        cmd := m[1]
    else
        cmd := trimmed

    SplitPath(cmd, &name, , &ext)
    if (ext = "")
        name .= ".exe"
    return name
}

; Resolve ahk_class / ahk_exe criteria, falling back to ahk_exe <target.exe>
ResolveWinTitle(target, winTitle := "") {
    if (winTitle != "") {
        trimmed := Trim(winTitle)
        if RegExMatch(trimmed, "i)^ahk_(class|exe|id|pid|group)\b")
            return trimmed
        if (SubStr(trimmed, -4) = ".exe")
            return "ahk_exe " . trimmed
        return "ahk_class " . trimmed
    }
    exe := ExtractExeName(target)
    return (exe != "") ? "ahk_exe " . exe : ""
}

; Launch an application, wait for window, and activate
; Options: { winTitle: "", wait: 5, notify: false }
LaunchApp(target, opts := {}) {
    winTitle := opts.HasProp("winTitle") ? opts.winTitle : ""
    waitTime := opts.HasProp("wait") ? opts.wait : 5
    notify := opts.HasProp("notify") ? opts.notify : false

    resolvedTitle := ResolveWinTitle(target, winTitle)

    try {
        Run(target)
    } catch as err {
        if (notify)
            ShowTooltip("Launch failed: " . err.Message)
        return false
    }

    if (resolvedTitle != "") {
        hwnd := WinWait(resolvedTitle, , waitTime)
        if (hwnd) {
            try WinActivate(hwnd)
            if (notify)
                ShowTooltip("Launched: " . ExtractExeName(target))
            return hwnd
        } else {
            if (notify)
                ShowTooltip("Launch timed out: " . resolvedTitle)
            return 0
        }
    }

    if (notify)
        ShowTooltip("Launched: " . ExtractExeName(target))
    return true
}

; Toggle a Windows service (running <-> stopped) using native Service Control Manager APIs
; Options: { notify: false, wait: 2500 }
ToggleService(serviceName, opts := {}) {
    notify := opts.HasProp("notify") ? opts.notify : false
    waitTimeoutMs := opts.HasProp("wait") ? opts.wait : 2500

    ; SC_MANAGER_CONNECT = 0x0001
    hSCM := DllCall("Advapi32\OpenSCManagerW", "Ptr", 0, "Ptr", 0, "UInt", 0x0001, "Ptr")
    if (!hSCM) {
        msg := "SCM error: " . A_LastError
        if (notify)
            ShowTooltip(msg)
        return msg
    }

    ; SERVICE_QUERY_STATUS = 0x0004, SERVICE_START = 0x0010, SERVICE_STOP = 0x0020
    desiredAccess := 0x0004 | 0x0010 | 0x0020
    hService := DllCall("Advapi32\OpenServiceW", "Ptr", hSCM, "Str", serviceName, "UInt", desiredAccess, "Ptr")
    if (!hService) {
        err := A_LastError
        DllCall("Advapi32\CloseServiceHandle", "Ptr", hSCM)
        msg := "Service '" . serviceName . "' open error (" . err . ")"
        if (notify)
            ShowTooltip(msg)
        return msg
    }

    QueryState(hSvc) {
        ss := Buffer(36, 0)
        bytesNeeded := 0
        if DllCall("Advapi32\QueryServiceStatusEx", "Ptr", hSvc, "Int", 0, "Ptr", ss, "UInt", 36, "UInt*", &bytesNeeded, "Int")
            return NumGet(ss, 4, "UInt")
        return -1
    }

    currentState := QueryState(hService)
    targetState := 0
    resultMsg := ""

    if (currentState == 4 || currentState == 2) { ; RUNNING or START_PENDING -> STOP
        ssControl := Buffer(28, 0)
        if !DllCall("Advapi32\ControlService", "Ptr", hService, "UInt", 1, "Ptr", ssControl, "Int")
            resultMsg := serviceName . ": Stop request failed (" . A_LastError . ")"
        else
            targetState := 1 ; SERVICE_STOPPED
    } else { ; STOPPED or other -> START
        if !DllCall("Advapi32\StartServiceW", "Ptr", hService, "UInt", 0, "Ptr", 0, "Int")
            resultMsg := serviceName . ": Start request failed (" . A_LastError . ")"
        else
            targetState := 4 ; SERVICE_RUNNING
    }

    if (targetState != 0) {
        startTime := A_TickCount
        while (A_TickCount - startTime < waitTimeoutMs) {
            st := QueryState(hService)
            if (st == targetState)
                break
            Sleep(50)
        }
        finalState := QueryState(hService)
        stateName := (finalState == 4) ? "Running" : (finalState == 1) ? "Stopped" : (finalState == 2) ? "Starting..." : (finalState == 3) ? "Stopping..." : "State " . finalState
        resultMsg := serviceName . ": " . stateName
    }

    DllCall("Advapi32\CloseServiceHandle", "Ptr", hService)
    DllCall("Advapi32\CloseServiceHandle", "Ptr", hSCM)

    if (notify)
        ShowTooltip(resultMsg)
    return resultMsg
}
