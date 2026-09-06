; "If you need more than what this does, think again."
; Simple Stupid Window Manager
#Requires AutoHotkey v2.0

; Load VirtualDesktopAccessor DLL
vdaDll := "C:\Users\" . A_UserName . "\bin\VirtualDesktopAccessor.dll"
hVDA := DllCall("LoadLibrary", "Str", vdaDll, "Ptr")

if (!hVDA) {
    MsgBox("Failed to load VirtualDesktopAccessor.dll from: " . vdaDll, "Error", "Iconx")
    ExitApp()
}

GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "GetDesktopCount", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "GetCurrentDesktopNumber", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "GoToDesktopNumber", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "CreateDesktop", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "MoveWindowToDesktopNumber", "Ptr")
GetWindowDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "GetWindowDesktopNumber", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "IsWindowOnDesktopNumber", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "IsPinnedWindow", "Ptr")
PinWindowProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "PinWindow", "Ptr")
UnPinWindowProc := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", "UnPinWindow", "Ptr")

global LastActiveWindows := Map()
global NavTargetDesktop := -1
global WorkspaceWindows := Map()
global PiercedWindows := Map()
global AltTabRemovedWindows := Map()

; Check if a workspace has any active or tracked windows
IsDesktopEmpty(desk) {
    global WorkspaceWindows, LastActiveWindows, IsWindowOnDesktopNumberProc

    if (desk == 10)
        return true

    ; Check LastActiveWindows
    if (LastActiveWindows.Has(desk)) {
        hwnd := LastActiveWindows[desk]
        if (DllCall("IsWindow", "Ptr", hwnd) && (!IsWindowOnDesktopNumberProc || DllCall(IsWindowOnDesktopNumberProc, "Ptr", hwnd, "Int", desk, "Int") == 1))
            return false
        else
            LastActiveWindows.Delete(desk)
    }

    ; Check WorkspaceWindows map
    if (WorkspaceWindows.Has(desk)) {
        hasValid := false
        for hwnd in WorkspaceWindows[desk].Clone() {
            if (DllCall("IsWindow", "Ptr", hwnd) && (!IsWindowOnDesktopNumberProc || DllCall(IsWindowOnDesktopNumberProc, "Ptr", hwnd, "Int", desk, "Int") == 1)) {
                hasValid := true
            } else {
                WorkspaceWindows[desk].Delete(hwnd)
            }
        }
        if (hasValid)
            return false
    }
    return true
}

; Initial scan of windows to populate WorkspaceWindows and LastActiveWindows
RefreshWorkspaceWindows() {
    global WorkspaceWindows, GetWindowDesktopNumberProc, IsWindowOnDesktopNumberProc, GetDesktopCountProc, GetCurrentDesktopNumberProc, LastActiveWindows
    count := DllCall(GetDesktopCountProc, "Int")
    if (count <= 0)
        return
    currentDesk := DllCall(GetCurrentDesktopNumberProc, "Int")
    newMap := Map()
    loop count {
        newMap[A_Index - 1] := Map()
    }

    prevDHW := A_DetectHiddenWindows
    DetectHiddenWindows True

    for hwnd in WinGetList() {
        try {
            cls := WinGetClass(hwnd)
            if (cls == "Shell_TrayWnd" || cls == "Shell_SecondaryTrayWnd" || cls == "Progman" || cls == "WorkerW")
                continue

            exStyle := WinGetExStyle(hwnd)
            if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW
                continue

            desk := -1
            if (GetWindowDesktopNumberProc) {
                desk := DllCall(GetWindowDesktopNumberProc, "Ptr", hwnd, "Int")
            }
            if (desk >= 0 && newMap.Has(desk)) {
                newMap[desk][hwnd] := true
            } else if (IsWindowOnDesktopNumberProc) {
                loop count {
                    dIdx := A_Index - 1
                    if (DllCall(IsWindowOnDesktopNumberProc, "Ptr", hwnd, "Int", dIdx, "Int") == 1) {
                        newMap[dIdx][hwnd] := true
                        break
                    }
                }
            } else {
                ; Check uncloaked on current desktop
                cloaked := 0
                DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", &cloaked, "UInt", 4)
                if (cloaked == 0 && currentDesk >= 0 && newMap.Has(currentDesk)) {
                    newMap[currentDesk][hwnd] := true
                }
            }
        }
    }

    DetectHiddenWindows prevDHW
    WorkspaceWindows := newMap
    SaveCurrentFocus()
}

RefreshWorkspaceWindows()

; Save active window on current workspace before leaving
SaveCurrentFocus() {
    global LastActiveWindows, GetCurrentDesktopNumberProc, WorkspaceWindows
    try {
        current := DllCall(GetCurrentDesktopNumberProc, "Int")
        activeHwnd := WinGetID("A")
        if (activeHwnd && current >= 0) {
            cls := WinGetClass(activeHwnd)
            if (cls != "Shell_TrayWnd" && cls != "Shell_SecondaryTrayWnd" && cls != "Progman" && cls != "WorkerW") {
                LastActiveWindows[current] := activeHwnd
                if (!WorkspaceWindows.Has(current))
                    WorkspaceWindows[current] := Map()
                WorkspaceWindows[current][activeHwnd] := true
            }
        }
    }
}

; Focus the appropriate window on the target workspace
FocusDesktop(target) {
    global LastActiveWindows, NavTargetDesktop, WorkspaceWindows, IsWindowOnDesktopNumberProc
    Sleep(50)
    if (NavTargetDesktop != -1)
        return

    ; 1. Restore previously active window on this desktop if still valid and on this desktop
    if (LastActiveWindows.Has(target)) {
        hwnd := LastActiveWindows[target]
        if (DllCall("IsWindow", "Ptr", hwnd) && !DllCall("IsIconic", "Ptr", hwnd)) {
            isOnDesk := (!IsWindowOnDesktopNumberProc || DllCall(IsWindowOnDesktopNumberProc, "Ptr", hwnd, "Int", target, "Int") == 1)
            if (isOnDesk) {
                try {
                    if (NavTargetDesktop != -1)
                        return
                    WinActivate(hwnd)
                    return
                }
            }
        }
        ; Stale handle or moved window
        LastActiveWindows.Delete(target)
    }
    ; 2. Fallback: activate top-most uncloaked window on this workspace
    for hwnd in WinGetList() {
        if (NavTargetDesktop != -1)
            return
        try {
            style := WinGetStyle(hwnd)
            exStyle := WinGetExStyle(hwnd)
            if (!(style & 0x10000000) || (exStyle & 0x00000080))
                continue
            cls := WinGetClass(hwnd)
            if (cls == "Shell_TrayWnd" || cls == "Shell_SecondaryTrayWnd" || cls == "Progman" || cls == "WorkerW")
                continue
            title := WinGetTitle(hwnd)
            if (title == "")
                continue
            cloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", &cloaked, "UInt", 4)
            if (cloaked == 0) {
                if (NavTargetDesktop != -1)
                    return
                WinActivate(hwnd)
                LastActiveWindows[target] := hwnd
                if (!WorkspaceWindows.Has(target))
                    WorkspaceWindows[target] := Map()
                WorkspaceWindows[target][hwnd] := true
                return
            }
        }
    }
}

; Settle focus after rapid navigation ceases
SettleDesktopFocus() {
    global NavTargetDesktop
    if (NavTargetDesktop < 0)
        return
    target := NavTargetDesktop
    NavTargetDesktop := -1
    FocusDesktop(target)
}

; Switch to workspace by 0-based index (auto-creates if it doesn't exist yet)
GoToDesktop(idx) {
    global GetDesktopCountProc, CreateDesktopProc, GoToDesktopNumberProc, NavTargetDesktop
    SetTimer(SettleDesktopFocus, 0)
    NavTargetDesktop := -1
    SaveCurrentFocus()
    count := DllCall(GetDesktopCountProc, "Int")
    while (count <= idx) {
        DllCall(CreateDesktopProc, "Int")
        count := DllCall(GetDesktopCountProc, "Int")
    }
    DllCall(GoToDesktopNumberProc, "Int", idx, "Int")
    FocusDesktop(idx)
}

; Move active window to workspace and switch to it (auto-creates if needed)
MoveWindowToDesktop(idx) {
    global GetDesktopCountProc, CreateDesktopProc, MoveWindowToDesktopNumberProc, GoToDesktopNumberProc, LastActiveWindows, NavTargetDesktop, WorkspaceWindows
    SetTimer(SettleDesktopFocus, 0)
    NavTargetDesktop := -1
    try {
        activeHwnd := WinGetID("A")
    } catch {
        activeHwnd := 0
    }
    count := DllCall(GetDesktopCountProc, "Int")
    while (count <= idx) {
        DllCall(CreateDesktopProc, "Int")
        count := DllCall(GetDesktopCountProc, "Int")
    }
    if (activeHwnd) {
        ; Swap active window in tracked workspace maps
        for desk, winMap in WorkspaceWindows {
            if (winMap.Has(activeHwnd))
                winMap.Delete(activeHwnd)
        }
        for desk, hwnd in LastActiveWindows.Clone() {
            if (hwnd == activeHwnd && desk != idx)
                LastActiveWindows.Delete(desk)
        }
        if (!WorkspaceWindows.Has(idx))
            WorkspaceWindows[idx] := Map()
        WorkspaceWindows[idx][activeHwnd] := true
        LastActiveWindows[idx] := activeHwnd

        DllCall(MoveWindowToDesktopNumberProc, "Ptr", activeHwnd, "Int", idx, "Int")
    }
    DllCall(GoToDesktopNumberProc, "Int", idx, "Int")
    if (activeHwnd) {
        Sleep(50)
        try WinActivate(activeHwnd)
    } else {
        FocusDesktop(idx)
    }
}

; Switch to next workspace (wraps around, non-blocking for rapid presses)
GoToNextDesktop(skipEmpty := false) {
    global NavTargetDesktop, GetCurrentDesktopNumberProc, GetDesktopCountProc, GoToDesktopNumberProc
    count := DllCall(GetDesktopCountProc, "Int")
    if (count <= 1)
        return

    if (NavTargetDesktop == -1) {
        SaveCurrentFocus()
        current := DllCall(GetCurrentDesktopNumberProc, "Int")
        if (current < 0)
            return
        NavTargetDesktop := current
    }

    next := NavTargetDesktop
    if (skipEmpty) {
        found := false
        loop count - 1 {
            next := (next + 1 >= count) ? 0 : next + 1
            if (!IsDesktopEmpty(next)) {
                found := true
                break
            }
        }
        if (!found)
            return
    } else {
        next := (next + 1 >= count) ? 0 : next + 1
    }

    NavTargetDesktop := next
    DllCall(GoToDesktopNumberProc, "Int", NavTargetDesktop, "Int")
    SetTimer(SettleDesktopFocus, -150)
}

; Switch to previous workspace (wraps around, non-blocking for rapid presses)
GoToPrevDesktop(skipEmpty := false) {
    global NavTargetDesktop, GetCurrentDesktopNumberProc, GetDesktopCountProc, GoToDesktopNumberProc
    count := DllCall(GetDesktopCountProc, "Int")
    if (count <= 1)
        return

    if (NavTargetDesktop == -1) {
        SaveCurrentFocus()
        current := DllCall(GetCurrentDesktopNumberProc, "Int")
        if (current < 0)
            return
        NavTargetDesktop := current
    }

    prev := NavTargetDesktop
    if (skipEmpty) {
        found := false
        loop count - 1 {
            prev := (prev - 1 < 0) ? count - 1 : prev - 1
            if (!IsDesktopEmpty(prev)) {
                found := true
                break
            }
        }
        if (!found)
            return
    } else {
        prev := (prev - 1 < 0) ? count - 1 : prev - 1
    }

    NavTargetDesktop := prev
    DllCall(GoToDesktopNumberProc, "Int", NavTargetDesktop, "Int")
    SetTimer(SettleDesktopFocus, -150)
}


; Helper: Get valid, visible, uncloaked windows on the current desktop
GetDesktopWindows() {
    wins := []
    for hwnd in WinGetList() {
        try {
            if (DllCall("IsIconic", "Ptr", hwnd))
                continue

            cls := WinGetClass(hwnd)
            if (cls == "Shell_TrayWnd" || cls == "Shell_SecondaryTrayWnd" || cls == "Progman" || cls == "WorkerW" || cls == "Windows.UI.Core.CoreWindow")
                continue

            style := WinGetStyle(hwnd)
            exStyle := WinGetExStyle(hwnd)
            if (!(style & 0x10000000) || (exStyle & 0x00000080)) ; WS_VISIBLE & not WS_EX_TOOLWINDOW
                continue

            title := WinGetTitle(hwnd)
            if (title == "")
                continue

            cloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", &cloaked, "UInt", 4)
            if (cloaked != 0)
                continue

            WinGetPos(&x, , &w, &h, hwnd)
            if (w <= 150 || h <= 150)
                continue

            wins.Push(hwnd)
        }
    }
    return wins
}

; Helper: Activate window and optionally center cursor using native MouseMove
ActivateAndCenter(hwnd, moveCursor := true) {
    global LastActiveWindows, GetCurrentDesktopNumberProc
    WinActivate(hwnd)
    try {
        current := DllCall(GetCurrentDesktopNumberProc, "Int")
        if (current >= 0)
            LastActiveWindows[current] := hwnd
    }
    if (moveCursor) {
        WinGetPos(&bx, &by, &bw, &bh, hwnd)
        MouseMove(bx + (bw // 2), by + (bh // 2), 0)
    }
}

; Focus window in 2D direction (dirX: -1=Left, 1=Right | dirY: -1=Up, 1=Down)
FocusDirection(dirX, dirY, moveCursor := true) {
    try {
        activeHwnd := WinExist("A")
        if (!activeHwnd)
            return

        WinGetPos(&curX, &curY, &curW, &curH, activeHwnd)
        curMidX := curX + (curW / 2)
        curMidY := curY + (curH / 2)

        bestHwnd := 0
        bestScore := 999999

        for hwnd in GetDesktopWindows() {
            if (hwnd == activeHwnd)
                continue

            WinGetPos(&x, &y, &w, &h, hwnd)
            midX := x + (w / 2)
            midY := y + (h / 2)

            if (dirX != 0) {
                ; Horizontal movement (Left / Right)
                dx := (dirX == -1) ? (curMidX - midX) : (midX - curMidX)
                if (dx <= 20)
                    continue

                dy := Abs(curMidY - midY)
                ; Check vertical overlap to heavily favor direct horizontal neighbours over diagonals
                overlapY := Max(0, Min(curY + curH, y + h) - Max(curY, y))
                penalty := (overlapY > 50) ? (dy * 0.5) : (dy * 3.0)
                score := dx + penalty

                if (score < bestScore) {
                    bestScore := score
                    bestHwnd := hwnd
                }
            } else if (dirY != 0) {
                ; Vertical movement (Up / Down)
                dy := (dirY == -1) ? (curMidY - midY) : (midY - curMidY)
                if (dy <= 20)
                    continue

                dx := Abs(curMidX - midX)
                ; Check horizontal overlap to heavily favor direct vertical neighbours over diagonals
                overlapX := Max(0, Min(curX + curW, x + w) - Max(curX, x))
                penalty := (overlapX > 50) ? (dx * 0.5) : (dx * 3.0)
                score := dy + penalty

                if (score < bestScore) {
                    bestScore := score
                    bestHwnd := hwnd
                }
            }
        }

        if (bestHwnd)
            ActivateAndCenter(bestHwnd, moveCursor)
    }
}

; Win + CapsLock / Win + Shift + CapsLock: Toggle/cycle between open windows in reading order (forward / reverse)
ToggleNextWindow(reverse := false, moveCursor := true) {
    try {
        wins := GetDesktopWindows()
        if (wins.Length <= 1)
            return

        ; Sort in spatial reading order (row by row, left to right)
        loop wins.Length - 1 {
            i := A_Index
            loop wins.Length - i {
                j := A_Index + i - 1
                WinGetPos(&x1, &y1, , , wins[j])
                WinGetPos(&x2, &y2, , , wins[j + 1])

                swap := false
                if (y1 > y2 + 100) {
                    swap := true
                } else if (y1 + 100 >= y2) {
                    ; Approximately same row
                    if (x1 > x2 + 50) {
                        swap := true
                    } else if (Abs(x1 - x2) <= 50 && wins[j] > wins[j + 1]) {
                        swap := true
                    }
                }

                if (swap) {
                    tmp := wins[j]
                    wins[j] := wins[j + 1]
                    wins[j + 1] := tmp
                }
            }
        }

        activeHwnd := WinExist("A")
        curIdx := 0
        for idx, hwnd in wins {
            if (hwnd == activeHwnd) {
                curIdx := idx
                break
            }
        }

        if (reverse) {
            nextIdx := (curIdx <= 1) ? wins.Length : curIdx - 1
        } else {
            nextIdx := (curIdx == 0 || curIdx >= wins.Length) ? 1 : curIdx + 1
        }

        ActivateAndCenter(wins[nextIdx], moveCursor)
    }
}

; Win + F5: Toggle pin active window across all virtual desktops
TogglePinActiveWindow() {
    global IsPinnedWindowProc, PinWindowProc, UnPinWindowProc
    try {
        activeHwnd := WinExist("A")
        if (!activeHwnd)
            return

        cls := WinGetClass(activeHwnd)
        if (cls == "Shell_TrayWnd" || cls == "Shell_SecondaryTrayWnd" || cls == "Progman" || cls == "WorkerW")
            return

        isPinned := DllCall(IsPinnedWindowProc, "Ptr", activeHwnd, "Int")
        if (isPinned == 1) {
            DllCall(UnPinWindowProc, "Ptr", activeHwnd, "Int")
        } else {
            DllCall(PinWindowProc, "Ptr", activeHwnd, "Int")
        }
    }
}

TogglePierceActiveWindow() {
    global PiercedWindows
    try {
        hwnd := WinExist("A")
        if (!hwnd)
            return
        cls := WinGetClass(hwnd)
        if (cls == "Shell_TrayWnd" || cls == "Shell_SecondaryTrayWnd" || cls == "Progman" || cls == "WorkerW")
            return

        if PiercedWindows.Has(hwnd) {
            original := PiercedWindows[hwnd]
            WinSetExStyle(original.exStyle, hwnd)
            if (!original.wasLayered)
                WinSetTransparent("Off", hwnd)
            DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0027)
            PiercedWindows.Delete(hwnd)
        } else {
            exStyle := WinGetExStyle(hwnd)
            wasLayered := (exStyle & 0x80000) != 0
            PiercedWindows[hwnd] := { exStyle: exStyle, wasLayered: wasLayered }

            if (!wasLayered)
                WinSetTransparent(255, hwnd)
            WinSetExStyle("+0x20", hwnd) ; WS_EX_TRANSPARENT
            DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0027)
        }
    }
}

RevertAllPiercedWindows() {
    global PiercedWindows
    try {
        for hwnd, original in PiercedWindows.Clone() {
            if WinExist(hwnd) {
                WinSetExStyle(original.exStyle, hwnd)
                if (!original.wasLayered)
                    WinSetTransparent("Off", hwnd)
                DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0027)
            }
        }
        PiercedWindows.Clear()
    }
}

ToggleAltTabActiveWindow() {
    global AltTabRemovedWindows
    try {
        hwnd := WinExist("A")
        if (!hwnd)
            return
        cls := WinGetClass(hwnd)
        if (cls == "Shell_TrayWnd" || cls == "Shell_SecondaryTrayWnd" || cls == "Progman" || cls == "WorkerW")
            return

        if AltTabRemovedWindows.Has(hwnd) {
            originalExStyle := AltTabRemovedWindows[hwnd]
            WinHide(hwnd)
            WinSetExStyle(originalExStyle, hwnd)
            WinShow(hwnd)
            WinActivate(hwnd)
            AltTabRemovedWindows.Delete(hwnd)
        } else {
            originalExStyle := WinGetExStyle(hwnd)
            AltTabRemovedWindows[hwnd] := originalExStyle
            WinHide(hwnd)
            WinSetExStyle("+0x80", hwnd)     ; WS_EX_TOOLWINDOW
            WinSetExStyle("-0x40000", hwnd)  ; Remove WS_EX_APPWINDOW
            WinShow(hwnd)
            WinActivate(hwnd)
        }
    }
}

RevertAllAltTabRemovedWindows() {
    global AltTabRemovedWindows
    try {
        for hwnd, originalExStyle in AltTabRemovedWindows.Clone() {
            if WinExist(hwnd) {
                WinHide(hwnd)
                WinSetExStyle(originalExStyle, hwnd)
                WinShow(hwnd)
            }
        }
        AltTabRemovedWindows.Clear()
    }
}

#MaxThreadsBuffer True
#MaxThreadsPerHotkey 10
; Win + 1..9 -> Switch to Workspaces 1..9 (0-indexed: 0..8)
#1:: GoToDesktop(0)
#2:: GoToDesktop(1)
#3:: GoToDesktop(2)
#4:: GoToDesktop(3)
#5:: GoToDesktop(4)
#6:: GoToDesktop(5)
#7:: GoToDesktop(6)
#8:: GoToDesktop(7)
#9:: GoToDesktop(8)
#0:: GoToDesktop(9)
#^Del:: GoToDesktop(10)

; Win + Shift + 1..9 -> Move active window to Workspaces 1..9
#+1:: MoveWindowToDesktop(0)
#+2:: MoveWindowToDesktop(1)
#+3:: MoveWindowToDesktop(2)
#+4:: MoveWindowToDesktop(3)
#+5:: MoveWindowToDesktop(4)
#+6:: MoveWindowToDesktop(5)
#+7:: MoveWindowToDesktop(6)
#+8:: MoveWindowToDesktop(7)
#+9:: MoveWindowToDesktop(8)
#+0:: MoveWindowToDesktop(9)
#^+Del:: MoveWindowToDesktop(10)

+CapsLock:: GoToPrevDesktop(true)
CapsLock:: GoToNextDesktop(true)
#+CapsLock:: ToggleNextWindow(true, true)
#CapsLock:: ToggleNextWindow(false, true)
#!CapsLock:: RefreshWorkspaceWindows()

#F1:: FocusDirection(-1, 0, true) ; Left
#F2:: FocusDirection(0, 1, true)  ; Down
#F3:: FocusDirection(0, -1, true) ; Up
#F4:: FocusDirection(1, 0, true)  ; Right
#F5:: TogglePinActiveWindow()     ; Pin/Unpin across all desktops
#F6:: TogglePierceActiveWindow()  ; Pierce through focused window
#+F6:: RevertAllPiercedWindows()  ; Revert all pierced through windows
#F7:: ToggleAltTabActiveWindow()  ; Remove/restore focused window from Alt+Tab
#+F7:: RevertAllAltTabRemovedWindows() ; Revert all windows removed from Alt+Tab
#MaxThreadsBuffer False
#MaxThreadsPerHotkey 1